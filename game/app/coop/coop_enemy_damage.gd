class_name CoopEnemyDamage
extends RefCounted
## Enemy impact composition, preserving each actor's guard, armor and immunity.

static func filter_hit(amount: float, direction: Vector3, kind: Damageable.HitKind, member: CoopActor) -> float:
	if member.world_items != null and MeadowBarn.contains(member.world_items.game.world.seed_bank, member.actor.global_position): return 0.0
	if kind == Damageable.HitKind.SLIME: return amount
	if member.actor.motor.is_dashing: return 0.0
	if member.combat.equipment.defend(member.actor.global_position - direction, amount):
		member.health.hit_absorbed = true
		member.block_count += 1
		return 0.0
	return amount * member.combat.incoming_damage_multiplier

static func hurt(member: CoopActor, amount: float, source: Vector3, kind: Damageable.HitKind) -> void:
	if member.spectating or member.actor.motor.is_dashing: return
	# Slime bypasses the general health filter; other kinds use it exactly once.
	if kind == Damageable.HitKind.SLIME:
		if member.combat.equipment.defend(source, amount):
			member.block_count += 1
			return
		amount *= member.combat.incoming_damage_multiplier
	var direction := Vector3.ZERO if kind == Damageable.HitKind.SLIME else member.actor.global_position - source
	if member.health.damage(amount, direction, kind):
		member.health.invulnerability = maxf(member.health.invulnerability, 0.8)
		CombatEffects.burst(member, member.actor.global_position, "-%d" % int(amount), Color("ff9b8c"))
