class_name ActorCombatMotion
extends RefCounted
## Explicit app bridge: combat requests velocity, Player applies ordinary collisions.

static func configure(actor: Player, combat: PlayerCombat) -> void:
	actor.ability_command = prepare.bind(actor, combat)
	actor.ability_velocity = velocity.bind(actor, combat)
	actor.ability_dashing = combat.claws.get.bind("dashing")
	actor.relocated.connect(combat.claws.cancel)

static func equipment(actor: Player, selected: bool) -> void:
	actor.motor.equipment_walk_multiplier = BengalClaws.WALK_BONUS if selected else 1.0
	actor.motor.dash_cooldown_multiplier = BengalClaws.DASH_COOLDOWN if selected else 1.0
	actor.motor.dash_cost_multiplier = BengalClaws.DASH_COST if selected else 1.0

static func prepare(command: PlayerCommand, actor: Player, combat: PlayerCombat) -> void:
	combat.claws.target_point = command.aim_point
	if command.cancel_actions or actor.transport_active: combat.claws.cancel()
	if not combat.claws.busy() and not (combat.claws.selected and command.guard_held): return
	command.dash_pressed = false
	command.dash_held = false
	command.jump_pressed = false
	command.jump_held = false
	actor.motor.cancel_jump()
	actor.motor.cancel_dash_charge()
	actor.motor.is_dashing = false
	actor.motor.is_super_dashing = false

static func velocity(current: Vector3, grounded: bool, delta: float, actor: Player, combat: PlayerCombat) -> Vector3:
	if combat.claws.dashing:
		actor.motor.is_dashing = false
		actor.motor.is_super_dashing = false
	return combat.claws.velocity(combat.plunge.velocity(current, grounded, delta), grounded, delta)
