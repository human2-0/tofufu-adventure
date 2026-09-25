class_name StaffAttack
extends RefCounted
## Staff shares knife rhythm; its secondary move sweeps a full circle.

const TORNADO: int = 5

static func duration(style: int, tuning: CombatTuning) -> float:
	return tuning.staff_tornado_seconds if style == TORNADO else KnifeAttack.duration(style, tuning)

static func pose(style: int, at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning) -> Transform3D:
	if style != TORNADO:
		return KnifeAttack.pose(style, at, aim, progress, tuning)
	var facing := SwordGeometry.direction(aim)
	var turn := clampf(inverse_lerp(tuning.cut_start, tuning.cut_end, progress), 0.0, 1.0)
	var angle := facing.angle() + turn * TAU
	var radial := Vector3(cos(angle), 0.0, sin(angle))
	var width := radial.cross(Vector3.UP).normalized()
	var basis := Basis(width, -radial.cross(width), -radial)
	var hand := at + radial * tuning.hand_radius + Vector3.UP * tuning.hand_height
	return Transform3D(basis, hand + radial * tuning.grip_length)

static func damage(style: int, tuning: CombatTuning) -> float:
	if style == TORNADO: return tuning.staff_tornado_damage
	return KnifeAttack.damage(style, tuning) * tuning.staff_power / maxf(tuning.knife_power, 1.0)
