class_name AdventureGame
extends Node3D
## Composition root: connects movement, combat, exploration and presentation.

const FART_CLOUD := preload("res://game/combat/abilities/fart_cloud.gd")

@export var play_opening: bool = true
var shooting_view: ShootingView
var chat: ProximityChat
var opening: PodOpening
var exploration: ExplorationSites
var farming: SoybeanFarming
var map: MapFlow
var parrot_travel: ParrotTravel

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
var weather_particles: WeatherParticles
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
var castle_adventure: CastleAdventure
var factory_dungeon: TofuDungeon
var meadow_harvest: MeadowHarvest
var apple_harvest: AppleHarvest
var apple_tree_targets: Array[Damageable] = []

func _ready() -> void:
	AdventureSetup.actor(self)
	AdventureSetup.inventory(self)
	AdventureSetup.encounters(self)
	AdventureSetup.weather(self)
	AdventureSetup.exploration(self)
	if play_opening:
		_start_opening()
	else:
		hud.announce("Welcome to Fufufarm / Soy fields, stodoła storage and Grandma Fufu beyond the bridge.")

func _physics_process(_delta: float) -> void:
	if opening != null and opening.active:
		return
	if TerrainLocomotion.fallen(player.position, world):
		_on_player_depleted()
	var in_water := world.is_water(player.position)
	TerrainLocomotion.apply(player, world)
	if in_water and not _in_water:
		hud.announce("Aquadepths / Walk the seabed; jump for a buoyant lift. Follow the sand back to shore." if TerrainLocomotion.immersion(player.position, world) > 0.0 else "Shallow water / Jump back onto the bank or find a bridge")
	_in_water = in_water

func _on_command(command: PlayerCommand, delta: float) -> void:
	ActorMeleeImpact.prepare(player, command)
	BarnPeace.prepare(self, player, combat, command)
	if command.cancel_actions: combat.reset()
	var moving := Vector2(player.velocity.x, player.velocity.z).length_squared() > 0.01
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and not combat.equipment.melee_selected() and not combat.ranged_selected()), command.drop_pressed, command.pickup_pressed, command.weapon_slot, delta, command.pickup_id)
	player.ability_velocity = combat.plunge.velocity
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
	if MeadowBarn.contains(world.seed_bank, at): return
	FART_CLOUD.spawn(self, at, combat.targets)

func _on_player_hit(_amount: float, _direction: Vector3) -> void:
	hud.show_damage_hit(health.last_hit_kind)
	camera.shake(0.18)
	player.visuals.modulate = Color("ffaaa0")
	var tween := create_tween()
	tween.tween_property(player.visuals, "modulate", Color.WHITE, 0.4)

func _respawn() -> void:
	player.relocate(DungeonMembership.checkpoint(factory_dungeon) if factory_dungeon != null and factory_dungeon.actor_in_run(player) else Vector3(0, 0.1, 0))
	player.velocity = Vector3.ZERO
	player.motor.is_dashing = false
	player.motor.is_super_dashing = false
	player.motor.cancel_jump()
	player.visuals.jump_animation.reset()
	health.restore()
	combat.reset()
	hud.announce("Back at the nursery / Fresh health. Keep exploring!")

func _on_player_depleted() -> void:
	if castle_adventure != null and castle_adventure.party.recover(player): return
	if factory_dungeon != null and factory_dungeon.actor_in_run(player) and factory_dungeon.puzzle_enabled:
		factory_dungeon.puzzle_runtime.release_actor(player)
		if factory_dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT:
			factory_dungeon.puzzle_flow.reset_encounter(factory_dungeon)
	if world_items != null and (factory_dungeon == null or not factory_dungeon.actor_in_run(player)): world_items.drop_on_death(combat)
	if seed_storage != null and (factory_dungeon == null or not factory_dungeon.actor_in_run(player)): seed_storage.reset_for_death()
	_respawn()

func _unhandled_input(event: InputEvent) -> void:
	if inventory_window.visible or (map != null and map.expanded): return
	if opening != null and opening.active:
		return
	if event.is_echo():
		return
	if event.is_action_pressed("return_to_camp"):
		if factory_dungeon != null and factory_dungeon.puzzle_enabled and factory_dungeon.actor_in_run(player): DungeonRunActions.open_menu(factory_dungeon)
		else: _respawn()
	elif event.is_action_pressed("skip_time"):
		cycle.phase = fposmod(cycle.phase + 0.25, 1.0)
	elif event.is_action_pressed("toggle_help"):
		if factory_dungeon != null and factory_dungeon.puzzle_enabled and factory_dungeon.actor_in_run(player): DungeonRunActions.toggle_journal(factory_dungeon)
		else: hud.toggle_help()
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
	hud.announce("Welcome to Fufufarm! / Follow the lane to the village and Grandma Fufu.")

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
