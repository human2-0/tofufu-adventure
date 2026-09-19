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

var _shake: float = 0.0

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)

func _ready() -> void:
	process_physics_priority = 100
	# Follow only the explicitly assigned local target
	if target:
		global_position = target.global_position + offset
		_update_camera_orientation()

func _physics_process(delta: float) -> void:
	if not target:
		return
		
	if first_person:
		_follow_first_person(delta)
		return
	if shoulder:
		_follow_shoulder(delta)
		return
	var target_position = target.global_position + offset
	global_position = global_position.lerp(target_position, 1.0 - exp(-smooth_speed * delta))
	_update_camera_orientation()
	_shake = move_toward(_shake, 0.0, delta * 0.8)
	h_offset = sin(Time.get_ticks_msec() * 0.08) * _shake
	v_offset = cos(Time.get_ticks_msec() * 0.06) * _shake * 0.6

func _update_camera_orientation() -> void:
	if target:
		# Follow the smoothed position, retaining exactly 45 degrees during jumps.
		var look_pos := global_position - offset + look_target_offset
		look_at(look_pos, Vector3.UP)

func set_shoulder(enabled: bool) -> void:
	first_person = false
	shoulder = enabled
	h_offset = 0.0
	v_offset = 0.0
	if not shoulder:
		fov = 48.0
		global_position = target.global_position + offset
		_update_camera_orientation()

func orbit(relative: Vector2) -> void:
	yaw -= relative.x * 0.003
	pitch = clampf(pitch + relative.y * 0.003, -1.35 if first_person else -0.4, 1.35 if first_person else 1.15)

func _follow_shoulder(delta: float) -> void:
	var back := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var pivot := target.global_position + Vector3.UP * 0.95
	var desired := pivot + back * (2.5 if precise else 4.2) + right * 0.55
	var ray := PhysicsRayQueryParameters3D.create(pivot, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	global_position = hit.position + hit.normal * 0.18 if not hit.is_empty() else desired
	look_at(global_position - back, Vector3.UP)
	fov = lerpf(fov, 42.0 if precise else 62.0, 1.0 - exp(-10.0 * delta))

func set_first_person() -> void:
	set_shoulder(true)
	first_person = true
	_follow_first_person(1.0)

func _follow_first_person(delta: float) -> void:
	global_position = target.global_position + Vector3.UP * 0.95
	rotation = Vector3(-pitch, yaw, 0.0)
	fov = lerpf(fov, 50.0 if precise else 78.0, 1.0 - exp(-10.0 * delta))
