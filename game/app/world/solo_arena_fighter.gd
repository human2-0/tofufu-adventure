class_name SoloArenaFighter
extends RefCounted
## Temporary solo match equipment and actor state, also used by save capture.

const SAVE_FIELDS: Array[String] = ["position", "health", "vitals", "claw_cooldown", "bow_reload", "bow_cooldown", "endurance", "progression", "inventory", "equipment", "active_slot", "pending_items", "knife_owned", "knife_selected", "gun_owned", "gun_selected", "sotjet_owned", "sotjet_selected", "soymilk", "dropped_position"]
var saved: Dictionary = {}
var combat_state: Dictionary = {}
var targets: Array[Damageable] = []
var drop_action: Callable
var pickup_action: Callable
var dash_cooldown: float = 0.0

func enter(game: AdventureGame) -> void:
	saved = AdventureSnapshot.capture(game, "Arena entry", 0.0)
	combat_state = CombatState.capture(game.combat)
	dash_cooldown = game.player.motor.cooldown_remaining
	targets = game.combat.targets.duplicate()
	drop_action = game.combat.equipment.drop_item
	pickup_action = game.combat.equipment.pickup_item
	clear_projectiles(game)
	game.combat.equipment.drop_item = Callable()
	game.combat.equipment.pickup_item = Callable()
	_training(game, false)
	game.progression.progress.restore(CharacterProgress.new().capture())
	for slot in ["helmet", "armor", "legs", "boots", "accessory", "support_1", "support_2", "support_3", "support_4"]:
		game.character_equipment.set_slot(slot, null)
	for index in 2:
		var item := InventoryItem.weapon("celestial_sword" if index == 0 else "soy_raygun")
		item.required_level = 1
		game.character_equipment.set_slot("combat_%d" % (index + 1), ItemStack.new(item, 1))
	game.loadout.active_slot = 1
	game.loadout.refresh(false)
	game.health.maximum = 180.0
	game.health.restore()
	game.combat.gun.magazine = game.combat.gun.magazine_capacity
	game.player.motor.cooldown_remaining = 0.0

func leave(game: AdventureGame) -> void:
	if saved.is_empty(): return
	clear_projectiles(game)
	game.progression.progress.restore(saved.progression)
	game.loadout.restore(saved.equipment, saved.active_slot)
	game.inventory.restore(saved.inventory)
	game.inventory.restore_pending(saved.pending_items)
	CombatState.restore(game.combat, combat_state)
	game.health.maximum = game.combat.tuning.maximum_health * pow(VitalRules.HP_GROWTH, game.progression.progress.level() - 1)
	game.health.current = float(saved.health)
	game.health.invulnerability = 2.0
	game.health.changed.emit(game.health.current, game.health.maximum)
	game.player.motor.endurance.restore(saved.endurance)
	game.combat.targets = targets.duplicate()
	game.combat.gun.targets = targets.duplicate()
	game.combat.sotjet.flow.targets = targets.duplicate()
	game.combat.equipment.drop_item = drop_action
	game.combat.equipment.pickup_item = pickup_action
	_training(game, true)
	var at := Vector3(saved.position[0], saved.position[1], saved.position[2])
	if not game.player.relocate(at): game.player.global_position = game.world.duel_arena.pad_exit_position(0)
	stop_motion(game.player)
	game.player.motor.cooldown_remaining = dash_cooldown
	saved.clear()

func checkpoint(data: Dictionary) -> Dictionary:
	for field in SAVE_FIELDS:
		if saved.has(field): data[field] = saved[field]
	return data

static func stop_motion(actor: Player) -> void:
	actor.velocity = Vector3.ZERO
	actor.motor.is_dashing = false
	actor.motor.is_super_dashing = false
	actor.motor.dash_remaining = 0.0
	actor.motor.cancel_jump()
	actor.motor.cancel_dash_charge()
	actor.motor.impact.clear()

static func clear_projectiles(game: AdventureGame) -> void:
	game.combat.bow.clear_flights()
	for child in game.combat.gun.get_children():
		if child is SoyProjectile: child.queue_free()
	game.combat.sotjet.flow.clear()
	game.combat.reset()

static func _training(game: AdventureGame, connected: bool) -> void:
	game.progression.care.enabled = connected
	var progress := game.progression.progress
	var defended := game.combat.equipment.defended
	if connected and not defended.is_connected(progress.defended): defended.connect(progress.defended)
	elif not connected and defended.is_connected(progress.defended): defended.disconnect(progress.defended)
