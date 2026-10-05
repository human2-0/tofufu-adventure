class_name StaffVisual
extends Node3D
## Supplied staff mesh, positioned on the same combat pose used for its hit volume.

const MODEL: PackedScene = preload("res://assets/weapons/sproutwood_staff/source/sproutwood_staff.glb")

const SOURCE_GRIP := Vector3(-0.08, -0.58, 0.0)
var grip := WeaponGripVisual.new()
var _hand := Vector3.ZERO
var _plane := Basis.IDENTITY
var _outward: float = 1.0
var _front: bool = true
var _has_hand: bool = false
var _pose := Transform3D.IDENTITY
var _attachment: float = 0.0
var _model: Node3D
var _meshes: Array[MeshInstance3D] = []
var _charge_glow: StandardMaterial3D
var _spin_glow: StandardMaterial3D

func _ready() -> void:
	add_child(grip)
	_model = MODEL.instantiate() as Node3D
	add_child(_model)
	# Meshy exports stand upright on +Y. Combat weapons extend forward on local -Z.
	_model.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3.ONE * 0.72), Vector3(-0.1, -0.29, -0.42))
	_set_shadows(_model)
	_charge_glow = _glow(Color(0.95, 0.84, 0.3, 0.35))
	_spin_glow = _glow(Color(0.45, 1.0, 0.55, 0.45))

func present(pose: Transform3D, charge: float = 0.0, spinning: bool = false, attachment: float = 0.0) -> void:
	_pose = pose
	_attachment = clampf(attachment, 0.0, 1.0)
	_apply_pose()
	show_charge(charge, spinning)

func follow_hand(hand: Vector3, plane: Basis, outward: float, in_front: bool) -> void:
	_hand = hand
	_plane = plane
	_outward = outward
	_front = in_front
	_has_hand = true
	grip.follow_wrist(hand, plane, outward, in_front)
	_apply_pose()

func model_grip_position() -> Vector3:
	return _model.to_global(SOURCE_GRIP)

func _apply_pose() -> void:
	global_transform = _pose
	if _has_hand and _attachment > 0.0:
		var blade := (_plane.y + _plane.x * _outward * 0.25).normalized()
		var width := blade.cross(_plane.z).normalized()
		var basis := Basis(width, -blade.cross(width), -blade)
		var contact := _hand + _plane.z * (0.035 if _front else -0.035)
		var held := Transform3D(basis, contact - basis * (_model.transform * SOURCE_GRIP))
		global_transform = _pose.interpolate_with(held, _attachment)
	grip.present(model_grip_position())

func show_charge(charge: float, spinning: bool = false) -> void:
	_charge_glow.albedo_color.a = clampf(charge, 0.0, 1.0) * 0.35
	for mesh in _meshes:
		mesh.material_overlay = _spin_glow if spinning else (_charge_glow if charge > 0.02 else null)

func _glow(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _set_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		_meshes.append(node)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for child in node.get_children():
		_set_shadows(child)
