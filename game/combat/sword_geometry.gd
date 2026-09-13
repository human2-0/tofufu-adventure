class_name SwordGeometry
extends RefCounted
## Authored hand mount and arc. Local -Z is steel, X width, Y thickness.

static func direction_index(aim: Vector2) -> int:
	return posmod(roundi(-aim.angle() / (PI / 4.0)), 8)

static func direction(aim: Vector2) -> Vector2:
	return Vector2.from_angle(-direction_index(aim) * PI / 4.0)

static func cutting(progress: float, tuning: CombatTuning) -> bool:
	return progress >= tuning.cut_start and progress <= tuning.cut_end

static func pose(at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning, heavy: bool = false) -> Transform3D:
	var facing := direction(aim)
	var idle_yaw := Vector2(-1.0 if facing.x < -0.1 else 1.0, 0.2).angle()
	var yaw := idle_yaw
	var pitch := tuning.idle_pitch_degrees
	if progress >= 0.0:
		var half_arc := deg_to_rad(tuning.heavy_arc_degrees if heavy else tuning.light_arc_degrees) * 0.5
		var start := facing.angle() - half_arc
		var end := facing.angle() + half_arc
		if progress < tuning.cut_start:
			var blend := smoothstep(0.0, tuning.cut_start, progress)
			yaw = lerp_angle(idle_yaw, start, blend)
			pitch = lerpf(pitch, 50.0, blend)
		elif progress <= tuning.cut_end:
			var blend := inverse_lerp(tuning.cut_start, tuning.cut_end, progress)
			yaw = lerpf(start, end, blend)
			pitch = lerpf(50.0, -12.0, blend)
		else:
			var blend := smoothstep(tuning.cut_end, 1.0, progress)
			yaw = lerp_angle(end, idle_yaw, blend)
			pitch = lerpf(-12.0, pitch, blend)
	var radial := Vector3(cos(yaw), 0, sin(yaw))
	var blade := radial * cos(deg_to_rad(pitch)) + Vector3.UP * sin(deg_to_rad(pitch))
	# Authored 45-degree sprite plane; shared by art and physics, not camera input.
	var width := blade.cross(Vector3(0, 1, 1).normalized()).normalized()
	if width.length_squared() < 0.01:
		width = Vector3.RIGHT
	var basis := Basis(width, -blade.cross(width), -blade)
	var hand := at + radial * tuning.hand_radius + Vector3.UP * tuning.hand_height
	return Transform3D(basis, hand + blade * tuning.grip_length)

static func tip(pose: Transform3D, tuning: CombatTuning) -> Vector3:
	return pose * Vector3(0, 0, -tuning.blade_length)

static func blade_transform(pose: Transform3D, tuning: CombatTuning) -> Transform3D:
	return pose.translated_local(Vector3(0, 0, -tuning.blade_length * 0.5))

static func guard_pose(at: Vector3, aim: Vector2, _tuning: CombatTuning) -> Transform3D:
	var forward := Vector3(aim.x, 0, aim.y).normalized()
	var side := Vector3(-forward.z, 0, forward.x)
	var blade := (side * 0.7 + Vector3.UP).normalized()
	var width := blade.cross(Vector3(0, 1, 1).normalized()).normalized()
	if width.length_squared() < 0.01:
		width = Vector3.RIGHT
	return Transform3D(Basis(width, -blade.cross(width), -blade), at + forward * 0.48 - side * 0.2 + Vector3.UP * 0.65)
