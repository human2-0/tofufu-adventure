extends Node3D
## Composition root: connects movement, combat, exploration and presentation.

@export var play_opening: bool = true
var shooting_view: ShootingView
var chat: ProximityChat
var opening: PodOpening
var exploration: ExplorationSites

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var cycle: EnvironmentCycle = $World/EnvironmentCycle
@onready var camera: CameraFollow = $Camera3D
@onready var world: Meadow = $World
var progression: ActorProgression
var combat: PlayerCombat
var health: Damageable
var encounters: SandboxEncounters
var weather: WeatherCycle
var weather_view: WeatherView
var _in_water: bool = false

func _ready() -> void:
	chat = ProximityChat.new()
	chat.game = self
	add_child(chat)
	player.dash_cooldown_updated.connect(hud.show_dash_cooldown)
	player.jump_charge_updated.connect(hud.show_jump_charge)
	hud.show_dash_cooldown(player.motor.cooldown_remaining, player.tuning.dash_cooldown)
	combat = PlayerCombat.new()
	combat.actor = player
	add_child(combat)
	player.visuals.hand_presented.connect(combat.sword.follow_hand)
	player.visuals.hand_presented.connect(combat.gun.visual.follow_hand)
	health = Damageable.new()
	health.maximum = combat.tuning.maximum_health
	health.body = player
	health.headshot_height = 0.78
	player.add_child(health)
	health.changed.connect(hud.show_health)
	health.depleted.connect(_respawn)
	health.hit.connect(_on_player_hit)
	hud.show_health(health.current, health.maximum)
	player.command_sampled.connect(_on_command)
	combat.charge_changed.connect(hud.show_charge)
	combat.equipment.changed.connect(hud.show_equipment)
	combat.equipment.punch_cadence_updated.connect(hud.show_punch_cadence)
	combat.struck.connect(_on_strike)
	progression = ActorProgression.new()
	progression.actor = player
	progression.combat = combat
	progression.hud = hud
	add_child(progression)
	encounters = SandboxEncounters.new()
	encounters.player = player
	encounters.combat = combat
	encounters.health = health
	encounters.experience_awarded.connect(progression.progress.award_experience)
	encounters.ground_point = world.ground_point
	encounters.mob_centers = FarmCombatGrounds.CAMPS
	encounters.dummy_positions = FarmCombatGrounds.DUMMIES
	encounters.protected_area = FarmCombatGrounds.VILLAGE
	add_child(encounters)
	encounters.progress_changed.connect(hud.show_progress)
	encounters.experience_changed.connect(hud.show_experience)
	encounters.populate()
	player.placement_peers.append(player)
	for mob in encounters.mob_nodes: player.placement_peers.append(mob)
	for mob in encounters.mob_nodes:
		mob.spawn_clearance = func(shape: CapsuleShape3D, at: Transform3D) -> bool:
			return not PlayerPlacement.overlaps_actors(mob, shape, at, player.placement_peers)
	weather = WeatherCycle.new()
	add_child(weather)
	weather_view = WeatherView.new()
	add_child(weather_view)
	var weather_flow := WeatherFlow.new()
	weather_flow.weather = weather
	weather_flow.cycle = cycle
	weather_flow.encounters = encounters
	weather_flow.view = weather_view
	add_child(weather_flow)
	exploration = ExplorationSites.new()
	exploration.explorer = player
	add_child(exploration)
	exploration.discovered.connect(hud.show_discovery)
	cycle.time_changed.connect(hud.show_time)
	shooting_view = ShootingView.new()
	shooting_view.game = self
	add_child(shooting_view)
	if play_opening:
		_start_opening()
	else:
		hud.announce("Welcome to Fufufarm / Soy fields, seed bank and a village beyond the bridge.")

func _physics_process(_delta: float) -> void:
	if opening != null and opening.active:
		return
	if player.position.y < -5.0:
		_respawn()
	var in_water := world.is_water(player.position)
	player.surface_speed = 0.55 if in_water else 1.0
	if in_water and not _in_water:
		hud.announce("Shallow water / Jump back onto the bank or find a bridge")
	_in_water = in_water

func _on_command(command: PlayerCommand, delta: float) -> void:
	if command.cancel_actions: combat.reset()
	var moving := Vector2(player.velocity.x, player.velocity.z).length_squared() > 0.01
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and not combat.equipment.knife_selected and not combat.gun.selected), command.drop_pressed, command.pickup_pressed, command.weapon_slot, delta)
	combat.step(command.aim, command.attack_held, delta, command.move if moving else Vector2.ZERO)
	combat.gun.targets = combat.targets
	combat.gun.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	player.visuals.attack_facing = combat.attack_aim if combat.active else (command.aim if combat.equipment.guarding or combat.gun.selected else Vector2.ZERO)

func _on_strike(strength: float, hits: int) -> void:
	if hits > 0:
		camera.shake(0.22 if strength >= 1.0 else 0.07)

func _on_player_hit(_amount: float, _direction: Vector3) -> void:
	hud.show_snail_hit()
	camera.shake(0.18)
	player.visuals.modulate = Color("ffaaa0")
	var tween := create_tween()
	tween.tween_property(player.visuals, "modulate", Color.WHITE, 0.4)

func _respawn() -> void:
	player.relocate(Vector3(0, 0.1, 0))
	player.velocity = Vector3.ZERO
	player.motor.is_dashing = false
	player.motor.cancel_jump()
	player.visuals.jump_animation.reset()
	health.restore()
	combat.reset()
	hud.announce("Back at the nursery / Fresh health. Keep exploring!")

func _unhandled_input(event: InputEvent) -> void:
	if opening != null and opening.active:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("return_to_camp"):
		_respawn()
	elif event.is_action_pressed("skip_time"):
		cycle.phase = fposmod(cycle.phase + 0.25, 1.0)
	elif event.is_action_pressed("toggle_help"):
		hud.toggle_help()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_F3:
		combat.sword.debug_visible = not combat.sword.debug_visible
		hud.announce("Sword hitbox overlay / " + ("ON" if combat.sword.debug_visible else "OFF"))

func _start_opening() -> void:
	weather_view.visible = false
	weather.set_physics_process(false)
	hud.visible = false
	combat.sword.visible = false
	encounters.process_mode = Node.PROCESS_MODE_DISABLED
	exploration.process_mode = Node.PROCESS_MODE_DISABLED
	opening = PodOpening.new()
	opening.player = player
	opening.camera = camera
	opening.completed.connect(_opening_completed)
	add_child(opening)

func _opening_completed() -> void:
	weather_view.visible = true
	weather.set_physics_process(true)
	hud.visible = true
	combat.sword.visible = true
	encounters.process_mode = Node.PROCESS_MODE_INHERIT
	exploration.process_mode = Node.PROCESS_MODE_INHERIT
	hud.announce("Welcome to Fufufarm! / Follow the lane to the village and Mayor Mame.")
