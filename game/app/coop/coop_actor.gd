class_name CoopActor
extends Node
## App composition for one owned actor's combat, health, respawn and replica view.

const FART_CLOUD := preload("res://game/combat/abilities/fart_cloud.gd")

signal time_requested
var actor: Player
var combat: PlayerCombat
var health: Damageable
var hud: HUD
var progression: ActorProgression
var loadout: ActorLoadout
var inventory: PlayerInventory
var character_equipment: CharacterEquipment
var quests := QuestState.new()
var healing: PlayerHealing
var world_items: WorldItems
var authority: bool = false
var respawn_count: int = 0
var duel_defeated: Callable
var block_count: int = 0
var last_command := PlayerCommand.new()
var target_state: Dictionary = {}
var prediction: CoopPrediction
var _view_age: float = 0
var motion := ReplicaMotion.new()
var spectating: bool = false

func _ready() -> void:
	# Resolve replica hands/facing before weapon child render callbacks and overlays.
	process_priority = -10
	_configure_combat()
	combat.replica_view = not authority
	_configure_loadout()
	if authority:
		if not health.hit.is_connected(ActorMeleeImpact.receive.bind(actor, combat, health)): health.hit.connect(ActorMeleeImpact.receive.bind(actor, combat, health))
		if not health.restored.is_connected(actor.motor.impact.clear): health.restored.connect(actor.motor.impact.clear)
		if not health.pushed.is_connected(actor.apply_push): health.pushed.connect(actor.apply_push)
		actor.super_dashed.connect(_on_super_dashed)
		combat.equipment.projectile_defended.connect(func() -> void: block_count += 1)
		actor.command_sampled.connect(_command)
		health.depleted.connect(die)
		health.damage_filter = _filter_hit
	else:
		actor.set_physics_process(false)
		health.set_physics_process(false)
		combat.sotjet.use_replica()

func _configure_combat() -> void:
	if combat == null:
		combat = PlayerCombat.new()
		combat.actor = actor
		add_child(combat)
		ActorWeaponHands.connect_visuals(actor.visuals, combat)
		health = Damageable.new()
		health.maximum = combat.tuning.maximum_health
		health.body = actor
		health.headshot_height = 0.78
		health.position.y = 0.55
		actor.add_child(health)
	combat.owner_health = health
	combat.gun.owner_health = health
	combat.sotjet.flow.owner_health = health
	health.projectile_guard = _reflect_projectile
	if not health.reflected_hit.is_connected(combat.gun.weapon_trained.emit):
		health.reflected_hit.connect(combat.gun.weapon_trained.emit)

func _configure_loadout() -> void:
	if progression == null:
		progression = ActorProgression.new()
		progression.actor = actor
		progression.combat = combat
		progression.hud = hud
		add_child(progression)
	if inventory == null: inventory = PlayerInventory.new()
	if character_equipment == null: character_equipment = CharacterEquipment.new()
	progression.equipment = character_equipment
	character_equipment.wearer_level = progression.progress.level()
	if loadout == null:
		loadout = ActorLoadout.new()
		loadout.combat = combat
		loadout.inventory = inventory
		loadout.equipment = character_equipment
		loadout.hud = hud
		add_child(loadout)
		loadout.seed()
	loadout.replica = not authority
	if healing == null:
		healing = PlayerHealing.new()
		healing.equipment = character_equipment
		healing.health = health
		healing.vitals = combat.vitals
		healing.eaten.connect(func(_n: String, amt: float) -> void: CombatEffects.burst(self, actor.global_position, "+%d HP (gradual)" % int(amt), Color("c8efa0")))

func _command(command: PlayerCommand, delta: float) -> void:
	if spectating: return
	ActorMeleeImpact.prepare(actor, command)
	if world_items != null: BarnPeace.prepare(world_items.game, actor, combat, command)
	last_command = command
	if command.cancel_actions: combat.reset()
	if command.camp_pressed and (world_items == null or not world_items.game.factory_dungeon.puzzle_enabled or not world_items.game.factory_dungeon.actor_in_run(actor)): respawn()
	if command.time_pressed: time_requested.emit()
	var moving := Vector2(actor.velocity.x, actor.velocity.z).length_squared() > 0.01
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and not combat.equipment.melee_selected() and not combat.ranged_selected()), command.drop_pressed, command.pickup_pressed, command.weapon_slot, delta, command.pickup_id)
	actor.ability_velocity = combat.plunge.velocity
	combat.step(command.aim, command.attack_held, delta, command.move if moving and not command.face_aim else Vector2.ZERO, not actor.is_on_floor(), command.guard_held)
	combat.gun.targets = combat.targets
	combat.gun.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	combat.sotjet.flow.targets = combat.targets
	combat.sotjet.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	actor.visuals.attack_facing = combat.attack_aim if combat.active else (command.aim if command.face_aim or combat.equipment.guarding or (combat.ranged_selected() and (command.attack_held or command.guard_held)) else Vector2.ZERO)
	if moving and not command.face_aim and not command.attack_held and not command.guard_held:
		combat.gun.visual.facing = command.move
		combat.sotjet.visual.facing = command.move
	if command.use_healing_1: healing.use_slot("support_1")
	if command.use_healing_2: healing.use_slot("support_2")
	if command.use_healing_3: healing.use_slot("support_3")
	if command.use_healing_4: healing.use_slot("support_4")
	healing.step(delta)

func hurt(amount: float, source: Vector3, kind: Damageable.HitKind = Damageable.HitKind.SLIME) -> void:
	CoopEnemyDamage.hurt(self, amount, source, kind)

func respawn() -> void:
	CoopDungeonDeath.respawn(self)

func die() -> void:
	if duel_defeated.is_valid():
		duel_defeated.call(self)
		return
	if world_items != null and world_items.game.castle_adventure.party.recover(actor): return
	if CoopDungeonDeath.defer(self): return
	if world_items != null and not world_items.game.factory_dungeon.actor_in_run(actor):
		world_items.drop_on_death(combat)
		if world_items.game.seed_storage != null: world_items.game.seed_storage.reset_for_death()
	respawn()

func capture() -> Dictionary:
	loadout.persist_reserve()
	var input_ack := (actor.command_source as RemotePlayerInput).consumed_sequence if actor.command_source is RemotePlayerInput else 0
	return {"parrot_rest": CoopValues.array3(actor.parrot_rest) if actor.parrot_rest.is_finite() else [], "transport": actor.transport_active, "quests": quests.capture(), "spectating": spectating, "input_ack": input_ack, "facing_locked": last_command.face_aim or last_command.attack_held or last_command.guard_held, "hits": health.hit_counts.duplicate(), "clearance": minf(100, actor._ground_clearance()), "position": CoopValues.array3(actor.position), "velocity": CoopValues.array3(actor.velocity),
		"endurance": actor.motor.endurance.capture(),
		"impact": actor.motor.impact.capture(),
		"aim": [last_command.aim.x, last_command.aim.y], "grounded": actor.is_on_floor() and not actor.transport_active,
		"dashing": actor.motor.is_dashing, "super_dashing": actor.motor.is_super_dashing, "charge": actor.motor.jump_charge, "cooldown": actor.motor.cooldown_remaining,
		"progression": progression.progress.capture(), "respawns": respawn_count, "blocks": block_count, "health": health.current, "invulnerability": health.invulnerability, "combat": CombatState.capture(combat),
		"active_slot": loadout.active_slot,
		"pending_items": inventory.pending_items.map(func(stack: ItemStack) -> Dictionary: return stack.capture()),
		"inventory": inventory.capture(), "equipment": character_equipment.capture()}

func restore(state: Dictionary, legacy_experience: int = 0) -> void:
	actor.parrot_rest = CoopValues.vector3(state.parrot_rest) if state.get("parrot_rest", []).size() == 3 else Vector3.INF
	quests.restore(state.get("quests", {}))
	progression.progress.restore(state.get("progression", {}), legacy_experience)
	respawn_count = int(state.get("respawns", 0))
	block_count = int(state.get("blocks", 0))
	var at := CoopValues.vector3(state.position)
	if world_items != null: at = TerrainLocomotion.saved_position(at, world_items.game.world)
	actor.relocate(at)
	actor.velocity = Vector3.ZERO
	actor.motor.endurance.restore(state.get("endurance", {}))
	actor.motor.cooldown_remaining = state.cooldown
	spectating = bool(state.get("spectating", false))
	health.current = 0.0 if spectating else maxf(1, state.health)
	health.invulnerability = state.invulnerability
	last_command.aim = Vector2(state.aim[0], state.aim[1])
	CombatState.restore(combat, state.combat)
	loadout.restore(state.get("equipment", {}), int(state.get("active_slot", 1)), state.combat)
	if state.has("inventory"): inventory.restore(state.get("inventory", []))
	inventory.restore_pending(state.get("pending_items", []))
	loadout.stow_ineligible_apparel()
	_refresh_hud(state)

func accept_view(state: Dictionary) -> void:
	CoopActorReplica.accept_view(self, state)

func _process(delta: float) -> void:
	CoopActorReplica.process(self, delta)

func _refresh_hud(state: Dictionary) -> void:
	CoopActorReplica.refresh_hud(self, state)

func _physics_process(delta: float) -> void:
	CoopActorReplica.physics_process(self, delta)

func _filter_hit(amount: float, direction: Vector3, kind: Damageable.HitKind) -> float:
	return CoopEnemyDamage.filter_hit(amount, direction, kind, self)

func _reflect_projectile(incoming: Vector3, point: Vector3, confirmed: bool) -> Vector3:
	if actor.motor.is_dashing: return Vector3.ZERO
	return combat.equipment.reflection_normal(incoming, point, confirmed)

func _on_super_dashed(at: Vector3) -> void:
	if world_items != null and MeadowBarn.contains(world_items.game.world.seed_bank, at): return
	FART_CLOUD.spawn(actor.get_parent(), at, combat.targets)
