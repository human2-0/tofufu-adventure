class_name CoopActor
extends Node
## App composition for one owned actor's combat, health, respawn and replica view.

signal time_requested
var actor: Player
var combat: PlayerCombat
var health: Damageable
var hud: HUD
var progression: ActorProgression
var inventory: PlayerInventory
var character_equipment: CharacterEquipment
var healing: PlayerHealing
var authority: bool = false
var respawn_count: int = 0
var block_count: int = 0
var last_command := PlayerCommand.new()
var target_state: Dictionary = {}
var prediction: CoopPrediction
var _view_age: float = 0

func _ready() -> void:
	if combat == null:
		combat = PlayerCombat.new()
		combat.actor = actor
		add_child(combat)
		actor.visuals.hand_presented.connect(combat.sword.follow_hand)
		actor.visuals.hand_presented.connect(combat.gun.visual.follow_hand)
		actor.visuals.hand_presented.connect(combat.sotjet.visual.follow_hand)
		health = Damageable.new()
		health.maximum = combat.tuning.maximum_health
		health.body = actor
		health.headshot_height = 0.78
		health.position.y = 0.55
		actor.add_child(health)
	combat.gun.owner_health = health
	combat.sotjet.flow.owner_health = health
	health.projectile_guard = _reflect_projectile
	if not health.reflected_hit.is_connected(combat.gun.weapon_trained.emit):
		health.reflected_hit.connect(combat.gun.weapon_trained.emit)
	if progression == null:
		progression = ActorProgression.new()
		progression.actor = actor
		progression.combat = combat
		progression.hud = hud
		add_child(progression)
	if inventory == null: inventory = PlayerInventory.new()
	if character_equipment == null: character_equipment = CharacterEquipment.new()
	if healing == null:
		healing = PlayerHealing.new()
		healing.equipment = character_equipment
		healing.health = health
		healing.eaten.connect(func(_n: String, amt: float) -> void: CombatEffects.burst(self, actor.global_position, "+%d HP (gradual)" % int(amt), Color("c8efa0")))
	if authority:
		combat.equipment.projectile_defended.connect(func() -> void: block_count += 1)
		actor.command_sampled.connect(_command)
		health.depleted.connect(respawn)
		health.damage_filter = _filter_hit
	else:
		actor.set_physics_process(false)
		health.set_physics_process(false)
		combat.sotjet.use_replica()

func _command(command: PlayerCommand, delta: float) -> void:
	last_command = command
	if command.cancel_actions: combat.reset()
	if command.camp_pressed: respawn()
	if command.time_pressed: time_requested.emit()
	var moving := Vector2(actor.velocity.x, actor.velocity.z).length_squared() > 0.01
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and not combat.equipment.knife_selected and not combat.ranged_selected()), command.drop_pressed, command.pickup_pressed, command.weapon_slot, delta)
	combat.step(command.aim, command.attack_held, delta, command.move if moving else Vector2.ZERO)
	combat.gun.targets = combat.targets
	combat.gun.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	combat.sotjet.flow.targets = combat.targets
	combat.sotjet.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	actor.visuals.attack_facing = combat.attack_aim if combat.active else (command.aim if combat.equipment.guarding or (combat.ranged_selected() and (command.attack_held or command.guard_held)) else Vector2.ZERO)
	if moving and not command.attack_held and not command.guard_held:
		combat.gun.visual.facing = command.move
		combat.sotjet.visual.facing = command.move
	if command.use_healing_1: healing.use_slot("healing_1")
	if command.use_healing_2: healing.use_slot("healing_2")
	healing.step(delta)

func hurt(amount: float, source: Vector3) -> void:
	if actor.motor.is_dashing: return
	if combat.equipment.defend(source):
		block_count += 1
		return
	amount *= combat.incoming_damage_multiplier
	if health.damage(amount, Vector3.ZERO, Damageable.HitKind.SLIME):
		health.invulnerability = maxf(health.invulnerability, 0.8)
		CombatEffects.burst(self, actor.global_position, "-%d" % int(amount), Color("ff9b8c"))

func respawn() -> void:
	respawn_count += 1
	actor.relocate(Vector3(0, 0.2, 2))
	actor.velocity = Vector3.ZERO
	actor.motor.is_dashing = false
	actor.motor.cancel_jump()
	actor.visuals.jump_animation.reset()
	health.restore()
	combat.reset()
	if hud != null: hud.announce("Back at the nursery / Fresh health. Your friends are waiting!")

func capture() -> Dictionary:
	var input_ack := (actor.command_source as RemotePlayerInput).consumed_sequence if actor.command_source is RemotePlayerInput else 0
	return {"input_ack": input_ack, "facing_locked": last_command.attack_held or last_command.guard_held, "hits": health.hit_counts.duplicate(), "clearance": minf(100, actor._ground_clearance()), "position": CoopValues.array3(actor.position), "velocity": CoopValues.array3(actor.velocity),
		"aim": [last_command.aim.x, last_command.aim.y], "grounded": actor.is_on_floor(),
		"dashing": actor.motor.is_dashing, "charge": actor.motor.jump_charge, "cooldown": actor.motor.cooldown_remaining,
		"progression": progression.progress.capture(), "respawns": respawn_count, "blocks": block_count, "health": health.current, "invulnerability": health.invulnerability, "combat": CombatState.capture(combat),
		"inventory": inventory.capture(), "equipment": character_equipment.capture()}

func restore(state: Dictionary, legacy_experience: int = 0) -> void:
	progression.progress.restore(state.get("progression", {}), legacy_experience)
	if state.has("inventory"): inventory.restore(state.get("inventory", []))
	if state.has("equipment"): character_equipment.restore(state.get("equipment", {}))
	respawn_count = int(state.get("respawns", 0))
	block_count = int(state.get("blocks", 0))
	actor.relocate(CoopValues.vector3(state.position))
	actor.velocity = Vector3.ZERO
	actor.motor.cooldown_remaining = state.cooldown
	health.current = maxf(1, state.health)
	health.invulnerability = state.invulnerability
	last_command.aim = Vector2(state.aim[0], state.aim[1])
	CombatState.restore(combat, state.combat)
	_refresh_hud(state)

func accept_view(state: Dictionary) -> void:
	if prediction != null: prediction.accept(state)
	if not target_state.is_empty() and state.health < target_state.health:
		CombatEffects.burst(self, actor.global_position, "-%.1f" % (target_state.health - state.health), Color("ff9b8c"))

	if not target_state.is_empty() and int(state.get("respawns", 0)) > int(target_state.get("respawns", 0)) and hud != null:
		hud.announce("Back at the nursery / Fresh health. Keep exploring together!")
	if not target_state.is_empty() and int(state.get("blocks", 0)) > int(target_state.get("blocks", 0)):
		CombatEffects.sparks(self, actor.position + Vector3(state.aim[0] * 0.65, 0.7, state.aim[1] * 0.65))
	if not target_state.is_empty() and hud != null:
		var before: Array = target_state.get("hits", [0, 0, 0])
		var after: Array = state.get("hits", [0, 0, 0])
		for kind in 3:
			if after[kind] > before[kind]: hud.show_damage_hit(kind)
	progression.progress.restore(state.get("progression", {}))
	health.current = state.health
	target_state = state
	_view_age = 0
	_refresh_hud(state)

func _process(delta: float) -> void:
	if authority or target_state.is_empty(): return
	_view_age += delta
	var state := target_state
	var command := PlayerCommand.new()
	command.aim = Vector2(state.aim[0], state.aim[1])
	command.move = Vector2(actor.velocity.x, actor.velocity.z).limit_length()
	command.attack_held = state.combat.charge > 0
	if prediction != null: command = prediction.command
	actor.visuals.attack_facing = Vector2(state.combat.aim[0], state.combat.aim[1]) if state.combat.active else (command.aim if state.combat.guard or ((state.combat.get("gun", false) or state.combat.get("jet", false)) and (command.attack_held or command.guard_held if prediction != null else state.get("facing_locked", false))) else Vector2.ZERO)
	actor.visuals.present(command, actor.velocity, actor.is_on_floor() if prediction != null else state.grounded, actor.motor.is_dashing if prediction != null else state.dashing, delta, actor.motor.jump_charge if prediction != null else state.charge, state.get("clearance", 100.0))
	var view: Dictionary = state.combat.duplicate()
	view.elapsed += minf(_view_age, 0.1) * combat.attack_speed_multiplier
	CombatState.present(combat, view, command.aim if command.move.is_zero_approx() or command.attack_held else command.move)

	if not command.move.is_zero_approx() and actor.visuals.attack_facing.is_zero_approx() and not command.attack_held:
		combat.gun.visual.facing = command.move
		combat.sotjet.visual.facing = command.move

func _refresh_hud(state: Dictionary) -> void:
	if hud == null: return
	hud.show_health(state.health, health.maximum)
	hud.show_dash_cooldown(state.cooldown, actor.tuning.dash_cooldown)
	hud.show_jump_charge(state.charge)
	hud.show_charge(state.combat.charge)
	hud.show_equipment(state.combat.owned, state.combat.selected, state.combat.guard)

func _filter_hit(amount: float, direction: Vector3, kind: Damageable.HitKind) -> float:
	if kind == Damageable.HitKind.SLIME: return amount
	if actor.motor.is_dashing: return 0.0
	if combat.equipment.defend(actor.global_position - direction):
		block_count += 1
		return 0.0
	return amount * combat.incoming_damage_multiplier

func _physics_process(delta: float) -> void:
	if authority or prediction != null or target_state.is_empty(): return
	var at := CoopValues.vector3(target_state.position)
	actor.velocity = CoopValues.vector3(target_state.velocity)
	at += actor.velocity * minf(_view_age, 0.1)
	actor.position = actor.position.lerp(at, 1.0 - exp(-22.0 * delta)) if actor.position.distance_to(at) < 5.0 else at

func _reflect_projectile(incoming: Vector3, point: Vector3, confirmed: bool) -> Vector3:
	if actor.motor.is_dashing: return Vector3.ZERO
	return combat.equipment.reflection_normal(incoming, point, confirmed)
