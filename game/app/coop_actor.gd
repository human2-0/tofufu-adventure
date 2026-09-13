class_name CoopActor
extends Node
## App composition for one owned actor's combat, health, respawn and replica view.

signal time_requested
var actor: Player
var combat: PlayerCombat
var health: Damageable
var hud: HUD
var progression: ActorProgression
var authority: bool = false
var respawn_count: int = 0
var block_count: int = 0
var last_command := PlayerCommand.new()
var target_state: Dictionary = {}
var _view_age: float = 0

func _ready() -> void:
	if combat == null:
		combat = PlayerCombat.new()
		combat.actor = actor
		add_child(combat)
		actor.visuals.hand_presented.connect(combat.sword.follow_hand)
		actor.visuals.hand_presented.connect(combat.gun.visual.follow_hand)
		health = Damageable.new()
		health.maximum = combat.tuning.maximum_health
		health.body = actor
		health.headshot_height = 0.78
		actor.add_child(health)
	if progression == null:
		progression = ActorProgression.new()
		progression.actor = actor
		progression.combat = combat
		progression.hud = hud
		add_child(progression)
	if authority:
		actor.command_sampled.connect(_command)
		health.depleted.connect(respawn)
	else:
		actor.set_physics_process(false)
		health.set_physics_process(false)

func _command(command: PlayerCommand, delta: float) -> void:
	last_command = command
	if command.cancel_actions: combat.reset()
	if command.camp_pressed: respawn()
	if command.time_pressed: time_requested.emit()
	var moving := Vector2(actor.velocity.x, actor.velocity.z).length_squared() > 0.01
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and not combat.equipment.knife_selected and not combat.gun.selected), command.drop_pressed, command.pickup_pressed, command.weapon_slot, delta)
	combat.step(command.aim, command.attack_held, delta, command.move if moving else Vector2.ZERO)
	combat.gun.targets = combat.targets
	combat.gun.step(command.attack_held and not command.cancel_actions, command.guard_held, command.aim, command.aim_point, delta)
	actor.visuals.attack_facing = combat.attack_aim if combat.active else (command.aim if combat.equipment.guarding or combat.gun.selected else Vector2.ZERO)

func hurt(amount: float, source: Vector3) -> void:
	if actor.motor.is_dashing: return
	if combat.equipment.defend(source):
		block_count += 1
		return
	amount *= combat.incoming_damage_multiplier
	if health.damage(amount):
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
	return {"clearance": minf(100, actor._ground_clearance()), "position": CoopValues.array3(actor.position), "velocity": CoopValues.array3(actor.velocity),
		"aim": [last_command.aim.x, last_command.aim.y], "grounded": actor.is_on_floor(),
		"dashing": actor.motor.is_dashing, "charge": actor.motor.jump_charge, "cooldown": actor.motor.cooldown_remaining,
		"progression": progression.progress.capture(), "respawns": respawn_count, "blocks": block_count, "health": health.current, "invulnerability": health.invulnerability, "combat": CombatState.capture(combat)}

func restore(state: Dictionary, legacy_experience: int = 0) -> void:
	progression.progress.restore(state.get("progression", {}), legacy_experience)
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
	if not target_state.is_empty() and state.health < target_state.health:
		CombatEffects.burst(self, actor.global_position, "-%d" % int(target_state.health - state.health), Color("ff9b8c"))
		if hud != null: hud.show_snail_hit()
	if not target_state.is_empty() and int(state.get("respawns", 0)) > int(target_state.get("respawns", 0)) and hud != null:
		hud.announce("Back at the nursery / Fresh health. Keep exploring together!")
	if not target_state.is_empty() and int(state.get("blocks", 0)) > int(target_state.get("blocks", 0)):
		CombatEffects.sparks(self, actor.position + Vector3(state.aim[0] * 0.65, 0.7, state.aim[1] * 0.65))
	progression.progress.restore(state.get("progression", {}))
	health.current = state.health
	target_state = state
	_view_age = 0
	_refresh_hud(state)

func _process(delta: float) -> void:
	if authority or target_state.is_empty(): return
	_view_age += delta
	var state := target_state
	var position := CoopValues.vector3(state.position)
	actor.position = actor.position.lerp(position, 1.0 - exp(-22.0 * delta)) if actor.position.distance_to(position) < 5 else position
	actor.velocity = CoopValues.vector3(state.velocity)
	var command := PlayerCommand.new()
	command.aim = Vector2(state.aim[0], state.aim[1])
	command.move = Vector2(actor.velocity.x, actor.velocity.z).limit_length()
	command.attack_held = state.combat.charge > 0
	actor.visuals.attack_facing = Vector2(state.combat.aim[0], state.combat.aim[1]) if state.combat.active else (command.aim if state.combat.get("gun", false) else Vector2.ZERO)
	actor.visuals.present(command, actor.velocity, state.grounded, state.dashing, delta, state.charge, state.get("clearance", 100.0))
	var view: Dictionary = state.combat.duplicate()
	view.elapsed += minf(_view_age, 0.1) * combat.attack_speed_multiplier
	CombatState.present(combat, view, command.aim if command.move.is_zero_approx() or command.attack_held else command.move)

func _refresh_hud(state: Dictionary) -> void:
	if hud == null: return
	hud.show_health(state.health, health.maximum)
	hud.show_dash_cooldown(state.cooldown, actor.tuning.dash_cooldown)
	hud.show_jump_charge(state.charge)
	hud.show_charge(state.combat.charge)
	hud.show_equipment(state.combat.owned, state.combat.selected, state.combat.guard)
