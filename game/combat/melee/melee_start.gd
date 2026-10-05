class_name MeleeStart
extends RefCounted
## Commits melee attacks only after resource payment, before touching attack state.

static func strike(combat: PlayerCombat, aim: Vector2, strength: float, airborne: bool) -> void:
	var bounded := clampf(strength, 0.0, 1.0)
	if bounded >= 1.0 and not combat.vitals.spend(VitalRules.SPECIAL_COST): return
	combat.special_attack = bounded >= 1.0
	combat.active = true
	combat.attack_aim = SwordGeometry.direction(aim)
	combat._strength = bounded
	combat.attack_style = KnifeAttack.select(combat._strength, combat.combo.can_stab(), airborne, combat.tuning)
	combat._set_melee_shape()
	combat.clash.clear()
	combat._attack_critical_chance = combat.combo.critical_chance()
	combat.combo.begin_attack()
	combat._elapsed = 0.0
	combat._hit_targets.clear()
	combat._trained = false
	combat._previous_at = combat.actor.global_position
	combat._previous_progress = 0.0

static func tornado(combat: PlayerCombat, aim: Vector2) -> void:
	if not combat.vitals.spend(VitalRules.SPECIAL_COST): return
	combat.rules.cancel_charge()
	combat.rules.cooldown = combat.tuning.staff_tornado_cooldown
	combat.clash.clear()
	combat.active = true
	combat.attack_aim = SwordGeometry.direction(aim)
	combat.special_attack = true
	combat.attack_style = StaffAttack.TORNADO
	combat._strength = 0.0
	combat._attack_critical_chance = 0.0
	combat.combo.begin_attack()
	combat._set_melee_shape()
	combat._elapsed = 0.0
	combat._hit_targets.clear()
	combat._trained = false
	combat._previous_at = combat.actor.global_position
	combat._previous_progress = 0.0
