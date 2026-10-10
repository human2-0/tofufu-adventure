class_name ActorMeleeImpact
extends RefCounted
## App wiring joins melee health outcomes to pure player motion and attack interruption.

static func receive(_amount: float, direction: Vector3, actor: Player, combat: PlayerCombat, health: Damageable) -> void:
	if health.last_hit_kind not in [Damageable.HitKind.KNIFE, Damageable.HitKind.MELEE]: return
	if direction.is_zero_approx() or health.current <= 0.0: return
	actor.apply_melee_hit(direction)
	combat.interrupt()

static func prepare(actor: Player, command: PlayerCommand) -> void:
	if actor.motor.impact.remaining <= 0.0: return
	command.attack_held = false
	command.guard_held = false
	command.punch_held = false
	command.drop_pressed = false
	command.weapon_slot = 0
