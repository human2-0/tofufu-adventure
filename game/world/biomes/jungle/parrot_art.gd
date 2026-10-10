class_name ParrotArt
extends Node3D
## Textured manga macaw: four shared draws, continuous heading and soft wing transitions.

var wings: Array[Node3D] = []
var _time: float = 0.0
var airborne: bool = false
var heading := Vector3.FORWARD
var _flap: float = 1.12
var _tail: Node3D

func _ready() -> void:
	process_priority = -7
	_view(self, ParrotPlumage.body())
	for side in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.33, 0.93, 0.02)
		add_child(wing)
		wings.append(wing)
		_view(wing, ParrotPlumage.wing()).scale.x = side
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.44, 0.65)
	add_child(_tail)
	_view(_tail, ParrotPlumage.tail())

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera != null and camera.global_position.distance_squared_to(global_position) > 14400: return
	_time += delta
	var turn := 0.0
	if Vector2(heading.x, heading.z).length_squared() > 0.25:
		var desired := atan2(-heading.x, -heading.z)
		turn = angle_difference(rotation.y, desired)
		rotation.y = lerp_angle(rotation.y, desired, 1.0 - exp(-9.0 * delta))
	rotation.z = lerp_angle(rotation.z, clampf(-turn * 0.2, -0.18, 0.18) if airborne else 0.0, 1.0 - exp(-5.0 * delta))
	var target := sin(_time * TAU * 1.8) * 0.55 if airborne else 1.12
	_flap = lerpf(_flap, target, 1.0 - exp(-18.0 * delta))
	# Mirrored wing bases share one surface and the same local hinge angle.
	wings[0].rotation.z = _flap
	wings[1].rotation.z = -_flap
	_tail.rotation.x = (0.06 if airborne else 0.20) + sin(_time * 3.0) * 0.035

func _view(parent: Node3D, mesh: Mesh) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.visibility_range_end = 120.0
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)
	return view
