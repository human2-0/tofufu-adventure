extends Node3D
## Composition root: connects movement, combat, exploration and presentation.

const FART_CLOUD := preload("res://game/combat/fart_cloud.gd")

@export var play_opening: bool = true
var shooting_view: ShootingView
var chat: ProximityChat
var opening: PodOpening
var exploration: ExplorationSites
var farming: SoybeanFarming
var map: MapFlow

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
var wind: WindField
var _in_water: bool = false
var inventory: PlayerInventory
var character_equipment: CharacterEquipment
var healing: PlayerHealing
var loadout: ActorLoadout
var merchant: WeaponMerchant
var quest_giver: QuestGiver
var world_items: WorldItems
var inventory_window: InventoryWindow
var seed_storage: SeedStorage
var factory_dungeon: TofuDungeon

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
	player.visuals.hand_presented.connect(combat.sotjet.visual.follow_hand)
	health = Damageable.new()
	health.maximum = combat.tuning.maximum_health
	health.body = player
	health.headshot_height = 0.78
	health.position.y = 0.55
	player.add_child(health)
	combat.owner_health = health
	combat.gun.owner_health = health
	combat.sotjet.flow.owner_health = health
	health.projectile_guard = _reflect_projectile
	if not health.reflected_hit.is_connected(combat.gun.weapon_trained.emit):
		health.reflected_hit.connect(combat.gun.weapon_trained.emit)
	health.changed.connect(hud.show_health)
	health.depleted.connect(_on_player_depleted)
	health.hit.connect(_on_player_hit)
	health.pushed.connect(player.apply_push)
	hud.show_health(health.current, health.maximum)
	player.command_sampled.connect(_on_command)
	combat.charge_changed.connect(hud.show_charge)
	combat.combo_changed.connect(hud.show_combo)
	combat.equipment.changed.connect(hud.show_equipment)
	combat.equipment.punch_cadence_updated.connect(hud.show_punch_cadence)
	combat.struck.connect(_on_strike)
	progression = ActorProgression.new()
	progression.actor = player
	progression.combat = combat
	progression.hud = hud
	add_child(progression)
	hud.stat_point_allocated.connect(progression.progress.allocate_stat)
	inventory = PlayerInventory.new()
	character_equipment = CharacterEquipment.new()
	progression.equipment = character_equipment
	character_equipment.wearer_level = progression.progress.level()
	loadout = ActorLoadout.new()
	loadout.combat = combat
	loadout.inventory = inventory
	loadout.equipment = character_equipment
	loadout.hud = hud
	add_child(loadout)
	loadout.seed()
	healing = PlayerHealing.new()
	healing.equipment = character_equipment
	healing.health = health
	healing.eaten.connect(_on_healing_eaten)
	healing.cooldown_updated.connect(_on_healing_cooldown_updated)
	character_equipment.changed.connect(_update_hud_healing)
	inventory_window = InventoryWindow.new()
	inventory_window.inventory = inventory
	inventory_window.equipment = character_equipment
	inventory_window.conversion_handler = func(slot: int, source_id: String) -> String: return CurrencyExchange.convert(inventory, slot, source_id)
	add_child(inventory_window)
	world_items = WorldItems.new()
	world_items.game = self
	add_child(world_items)
	var inventory_controls := InventoryControls.new()
	inventory_controls.game = self
	add_child(inventory_controls)
	seed_storage = SeedStorage.new()
	seed_storage.game = self
	add_child(seed_storage)
	encounters = SandboxEncounters.new()
	encounters.player = player
	encounters.combat = combat
	encounters.health = health
	encounters.inventory = inventory
	encounters.shell_drop = world_items.spawn_mob_loot
	encounters.experience_awarded.connect(progression.progress.award_experience)
	encounters.ground_point = world.ground_point
	encounters.mob_centers = FarmCombatGrounds.CAMPS
	encounters.dummy_positions = FarmCombatGrounds.DUMMIES
	encounters.protected_area = FarmCombatGrounds.VILLAGE
	add_child(encounters)
	encounters.progress_changed.connect(hud.show_progress)
	encounters.experience_changed.connect(hud.show_experience)
	encounters.populate()
	player.super_dashed.connect(_on_super_dashed)
	player.placement_peers.append(player)
	for mob in encounters.mob_nodes: player.placement_peers.append(mob)
	for mob in encounters.mob_nodes:
		mob.spawn_clearance = func(shape: CapsuleShape3D, at: Transform3D) -> bool:
			return not PlayerPlacement.overlaps_actors(mob, shape, at, player.placement_peers)
	weather = WeatherCycle.new()
	add_child(weather)
	wind = WindField.new()
	player.movement_modifier = wind.movement_multiplier
	weather_view = WeatherView.new()
	add_child(weather_view)
	var weather_flow := WeatherFlow.new()
	weather_flow.weather = weather
	weather_flow.cycle = cycle
	weather_flow.encounters = encounters
	weather_flow.view = weather_view
	weather_flow.ground = world.rain_effects
	weather_flow.wind = wind
	weather_flow.grass = world.grass_material
	add_child(weather_flow)
	exploration = ExplorationSites.new()
	exploration.explorer = player
	add_child(exploration)
	exploration.discovered.connect(hud.show_discovery)
	cycle.time_changed.connect(hud.show_time)
	shooting_view = ShootingView.new()
	shooting_view.game = self
	add_child(shooting_view)
	merchant = WeaponMerchant.new()
	merchant.game = self
	add_child(merchant)
	quest_giver = QuestGiver.new()
	quest_giver.game = self
	add_child(quest_giver)
	factory_dungeon = TofuDungeon.new()
	factory_dungeon.game = self
	add_child(factory_dungeon)
	map = MapFlow.new()
	map.game = self
	add_child(map)
	farming = SoybeanFarming.new()
	farming.game = self
	add_child(farming)
	if play_opening:
		_start_opening()
	else:
		hud.announce("Welcome to Fufufarm / Soy fields, seed bank and a village beyond the bridge.")

func _physics_process(_delta: float) -> void:
	if opening != null and opening.active:
		return
	if player.position.y < -5.0:
		_on_player_depleted()
	var in_water := world.is_water(player.position)
	player.surface_speed = 0.55 if in_water else 1.0
	if in_water and not _in_water:
		hud.announce("Shallow water / Jump back onto the bank or find a bridge")
	_in_water = in_water

func _on_command(command: PlayerCommand, delta: float) -> void:
	if command.cancel_actions: combat.reset()
	var moving := Vector2(player.velocity.x, player.velocity.z).length_squared() > 0.01
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and not combat.equipment.melee_selected() and not combat.ranged_selected()), command.drop_pressed, command.pickup_pressed, command.weapon_slot, delta, command.pickup_id)
	combat.step(command.aim, command.attack_held, delta, command.move if moving and not command.face_aim else Vector2.ZERO, not player.is_on_floor(), command.guard_held)
	combat.gun.targets = combat.targets
	combat.gun.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	combat.sotjet.flow.targets = combat.targets
	combat.sotjet.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	player.visuals.attack_facing = combat.attack_aim if combat.active else (command.aim if command.face_aim or combat.equipment.guarding or (combat.ranged_selected() and (command.attack_held or command.guard_held)) else Vector2.ZERO)
	if moving and not command.face_aim and not command.attack_held and not command.guard_held:
		combat.gun.visual.facing = command.move
		combat.sotjet.visual.facing = command.move
	if command.use_healing_1: healing.use_slot("support_1")
	if command.use_healing_2: healing.use_slot("support_2")
	if command.use_healing_3: healing.use_slot("support_3")
	if command.use_healing_4: healing.use_slot("support_4")
	healing.step(delta)

func _on_strike(strength: float, hits: int) -> void:
	if hits > 0:
		camera.shake(0.22 if strength >= 1.0 else 0.07)

func _on_super_dashed(at: Vector3) -> void:
	FART_CLOUD.spawn(self, at, combat.targets)

func _on_player_hit(_amount: float, _direction: Vector3) -> void:
	hud.show_damage_hit(health.last_hit_kind)
	camera.shake(0.18)
	player.visuals.modulate = Color("ffaaa0")
	var tween := create_tween()
	tween.tween_property(player.visuals, "modulate", Color.WHITE, 0.4)

func _respawn() -> void:
	player.relocate(Vector3(0, 0.1, 0))
	player.velocity = Vector3.ZERO
	player.motor.is_dashing = false
	player.motor.is_super_dashing = false
	player.motor.cancel_jump()
	player.visuals.jump_animation.reset()
	health.restore()
	combat.reset()
	hud.announce("Back at the nursery / Fresh health. Keep exploring!")

func _on_player_depleted() -> void:
	if world_items != null: world_items.drop_on_death(combat)
	if seed_storage != null: seed_storage.reset_for_death()
	_respawn()

func _unhandled_input(event: InputEvent) -> void:
	if inventory_window.visible or (map != null and map.expanded): return
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
	combat.staff.visible = false
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
	combat.sword.visible = combat.equipment.knife_selected
	combat.staff.visible = combat.equipment.staff_selected
	encounters.process_mode = Node.PROCESS_MODE_INHERIT
	exploration.process_mode = Node.PROCESS_MODE_INHERIT
	hud.announce("Welcome to Fufufarm! / Follow the lane to the village and Mayor Mame.")

func _reflect_projectile(incoming: Vector3, point: Vector3, confirmed: bool) -> Vector3:
	if player.motor.is_dashing: return Vector3.ZERO
	return combat.equipment.reflection_normal(incoming, point, confirmed)

func _on_healing_eaten(_item_name: String, amount: float) -> void:
	CombatEffects.burst(self, player.global_position, "+%d HP (gradual)" % int(amount), Color("c8efa0"))
	_update_hud_healing()

func _on_healing_cooldown_updated(remaining: float, _total: float) -> void:
	var stack := character_equipment.get_slot("healing_1")
	if stack != null and stack.item != null: hud.show_healing_slot(stack.item.name, stack.count, remaining)
	else: hud.show_healing_slot("", 0)

func _update_hud_healing() -> void:
	var stack := character_equipment.get_slot("healing_1")
	if stack != null and stack.item != null: hud.show_healing_slot(stack.item.name, stack.count, healing.cooldown_remaining)
	else: hud.show_healing_slot("", 0)
