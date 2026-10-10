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
	if progress >= 0.0:
		return MeleeArc.pose(at, aim, progress, tuning, KnifeAttack.Style.HEAVY if heavy else KnifeAttack.Style.SLASH)
	var facing := direction(aim)
	var yaw := Vector2(-1.0 if facing.x < -0.1 else 1.0, 0.2).angle()
	var pitch := tuning.idle_pitch_degrees
	var radial := Vector3(cos(yaw), 0, sin(yaw))
	var blade := radial * cos(deg_to_rad(pitch)) + Vector3.UP * sin(deg_to_rad(pitch))
	var width := Vector3(-sin(yaw), 0, cos(yaw))
	var basis := Basis(width, -blade.cross(width), -blade)
	var hand := at + radial * tuning.hand_radius + Vector3.UP * tuning.hand_height
	return Transform3D(basis, hand + blade * tuning.grip_length)

static func stab_pose(at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning) -> Transform3D:
	var facing := direction(aim)
	var forward := Vector3(facing.x, 0, facing.y)
	var blade := (forward + Vector3.UP * 0.12).normalized()
	var extension := 0.08
	if progress < tuning.cut_start:
		extension = lerpf(0.08, 0.32, smoothstep(0.0, tuning.cut_start, progress))
	elif progress <= tuning.cut_end:
		extension = lerpf(0.32, 0.68, MeleeArc.cut_weight(progress, tuning))
	else:
		extension = lerpf(0.68, 0.08, smoothstep(tuning.cut_end, 1.0, progress))
	var width := blade.cross(Vector3(0, 1, 1).normalized()).normalized()
	if width.length_squared() < 0.01:
		width = Vector3.RIGHT
	var basis := Basis(width, -blade.cross(width), -blade)
	var hand := at + forward * (tuning.hand_radius + extension) + Vector3.UP * tuning.hand_height
	return Transform3D(basis, hand + blade * tuning.grip_length)

static func dive_pose(at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning) -> Transform3D:
	var facing := direction(aim)
	var half_arc := deg_to_rad(tuning.light_arc_degrees) * 0.32
	var yaw := facing.angle() + lerpf(-half_arc, half_arc, clampf(progress, 0.0, 1.0))
	var radial := Vector3(cos(yaw), 0, sin(yaw))
	var blade := (radial * 0.68 + Vector3.DOWN * 0.73).normalized()
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
