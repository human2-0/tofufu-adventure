class_name MeleeArc
extends RefCounted
## Smooth attack acceleration; one world-space curve for visible steel and contact.

static func cut_weight(progress: float, tuning: CombatTuning) -> float:
	return smoothstep(tuning.cut_start, tuning.cut_end, progress)

static func pose(at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning, style: int) -> Transform3D:
	var facing := SwordGeometry.direction(aim)
	var idle_yaw := Vector2(-1.0 if facing.x < -0.1 else 1.0, 0.2).angle()
	var cut := cut_weight(progress, tuning)
	var launch := style == KnifeAttack.Style.LAUNCHER
	var reverse := style == KnifeAttack.Style.REVERSE_SLASH
	var half_arc := deg_to_rad(tuning.heavy_arc_degrees if style == KnifeAttack.Style.HEAVY else tuning.light_arc_degrees) * 0.5
	var yaw := facing.angle() + lerpf(-half_arc, half_arc, cut)
	var pitch := lerpf(50.0, -12.0, cut)
	if launch:
		yaw = facing.angle() + lerpf(-0.28, 0.28, cut)
		pitch = lerpf(-32.0, 68.0, cut)
	elif reverse:
		yaw = facing.angle() + lerpf(half_arc, -half_arc, cut)
		pitch = lerpf(28.0, -8.0, cut)
	if progress < tuning.cut_start:
		var wind := smoothstep(0.0, tuning.cut_start, progress)
		yaw = lerp_angle(idle_yaw, yaw, wind)
		pitch = lerpf(tuning.idle_pitch_degrees, pitch, wind)
	elif progress > tuning.cut_end:
		var recovery := smoothstep(tuning.cut_end, 1.0, progress)
		yaw = lerp_angle(yaw, idle_yaw, recovery)
		pitch = lerpf(pitch, tuning.idle_pitch_degrees, recovery)
	var radial := Vector3(cos(yaw), 0, sin(yaw))
	var blade := radial * cos(deg_to_rad(pitch)) + Vector3.UP * sin(deg_to_rad(pitch))
	# The tangent stays stable even when the blade crosses the billboard plane.
	var width := Vector3(-sin(yaw), 0, cos(yaw))
	var hand := at + radial * tuning.hand_radius + Vector3.UP * tuning.hand_height
	return Transform3D(Basis(width, -blade.cross(width), -blade), hand + blade * tuning.grip_length)
