class_name CameraFollow
extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 14.3, 13.5)
@export var look_target_offset: Vector3 = Vector3(0.0, 0.8, 0.0)
@export var smooth_speed: float = 7.0

var first_person: bool = false
var shoulder: bool = false
var precise: bool = false
var yaw: float = 0.0
var pitch: float = 0.12

var overhead_direction: int = 0 # North, East, South, West (screen up).
var shoulder_side: float = 1.0 # +1 right shoulder, -1 left shoulder.
var _overhead_yaw: float = 0.0
var _shoulder_blend: float = 1.0

var _shake: float = 0.0
var _motion := CameraMotion.new()
var _view_target: Vector3
var _boom_fraction: float = 1.0

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _ready() -> void:
	process_physics_priority = 100
	process_priority = -20
	# Follow only the explicitly assigned local target
	if target:
		_motion.reset(target.global_position)
		_view_target = target.global_position
		global_position = target.global_position + overhead_offset()
		_update_camera_orientation()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	_motion.push(target.global_position)
	if shoulder and not first_person: _sample_collision()
	# Headless scenarios exercise the same camera path without render callbacks.
	if DisplayServer.get_name() == "headless":
		_view_target = target.global_position
		_follow(delta)

func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless": return
	if not is_instance_valid(target) or not _motion.initialized: return
	_view_target = _motion.sample(Engine.get_physics_interpolation_fraction())
	_follow(delta)

func reset_follow() -> void:
	if not is_instance_valid(target): return
	_motion.reset(target.global_position)
	_view_target = target.global_position
	_boom_fraction = 1.0
	if not shoulder: global_position = _view_target + overhead_offset()
	_follow(0.0)

func _follow(delta: float) -> void:
	if first_person:
		_follow_first_person(delta)
		return
	if shoulder:
		_follow_shoulder(delta)
		return
	var weight := 1.0 - exp(-smooth_speed * delta)
	var followed_position := global_position - overhead_offset()
	_overhead_yaw = lerp_angle(_overhead_yaw, -overhead_direction * PI * 0.5, weight)
	global_position = followed_position.lerp(_view_target, weight) + overhead_offset()
	_update_camera_orientation()
	_shake = move_toward(_shake, 0.0, delta * 0.8)
	h_offset = sin(Time.get_ticks_msec() * 0.08) * _shake
	v_offset = cos(Time.get_ticks_msec() * 0.06) * _shake * 0.6

func _update_camera_orientation() -> void:
	if target:
		# Follow the smoothed position, retaining exactly 45 degrees during jumps.
		var look_pos := global_position - overhead_offset() + look_target_offset
		look_at(look_pos, Vector3.UP)

func set_shoulder(enabled: bool) -> void:
	_view_target = target.global_position
	_motion.reset(_view_target)
	_boom_fraction = 1.0
	first_person = false
	shoulder = enabled
	h_offset = 0.0
	v_offset = 0.0
	if not shoulder:
		fov = 48.0
		global_position = target.global_position + overhead_offset()
		_update_camera_orientation()

func switch_direction() -> String:
	if first_person: return ""
	if shoulder:
		shoulder_side *= -1.0
		return "Behind Fufu / %s shoulder" % ("Right" if shoulder_side > 0.0 else "Left")
	overhead_direction = (overhead_direction + 1) % 4
	return "Overhead / Facing " + ["North", "East", "South", "West"][overhead_direction]

func overhead_offset() -> Vector3:
	return offset.rotated(Vector3.UP, _overhead_yaw)

func orbit(relative: Vector2) -> void:
	yaw -= relative.x * 0.003
	pitch = clampf(pitch + relative.y * 0.003, -1.35 if first_person else -0.4, 1.35 if first_person else 1.15)

func _follow_shoulder(delta: float) -> void:
	_shoulder_blend = lerpf(_shoulder_blend, shoulder_side, 1.0 - exp(-10.0 * delta))
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var pivot := _view_target + Vector3.UP * 0.95
	global_position = pivot + _boom_offset() * _boom_fraction
	look_at(global_position - back, Vector3.UP)
	fov = lerpf(fov, 42.0 if precise else 62.0, 1.0 - exp(-10.0 * delta))

func _boom_offset() -> Vector3:
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	return back * (2.5 if precise else 4.2) + Vector3(cos(yaw), 0, -sin(yaw)) * (0.55 * _shoulder_blend)

func _sample_collision() -> void:
	# Query the physics space on physics ticks, while camera motion renders freely.
	var pivot := target.global_position + Vector3.UP * 0.95
	var boom := _boom_offset()
	var ray := PhysicsRayQueryParameters3D.create(pivot, pivot + boom, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	_boom_fraction = clampf((pivot.distance_to(hit.position) - 0.18) / boom.length(), 0.0, 1.0) if not hit.is_empty() else 1.0

func set_first_person() -> void:
	set_shoulder(true)
	first_person = true
	_follow_first_person(1.0)

func _follow_first_person(delta: float) -> void:
	global_position = _view_target + Vector3.UP * 0.95
	rotation = Vector3(-pitch, yaw, 0.0)
	fov = lerpf(fov, 50.0 if precise else 78.0, 1.0 - exp(-10.0 * delta))
