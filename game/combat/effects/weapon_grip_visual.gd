class_name WeaponGripVisual
extends Node3D
## Cosmetic right wrist-to-grip bridge. Never changes the weapon's damage pose.

const SHADER: Shader = preload("res://game/combat/effects/weapon_grip.gdshader")
var _hand: MeshInstance3D
var _arm: MeshInstance3D
var _material: ShaderMaterial
var _wrist := Vector3.ZERO
var _plane := Basis.IDENTITY
var _has_wrist: bool = false
var _front: bool = true

func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_hand = MeshInstance3D.new()
	var hand_mesh := SphereMesh.new()
	hand_mesh.radius = 0.055
	hand_mesh.height = 0.11
	_hand.mesh = hand_mesh
	_arm = MeshInstance3D.new()
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.035
	arm_mesh.bottom_radius = 0.043
	arm_mesh.height = 1.0
	_arm.mesh = arm_mesh
	for part in [_hand, _arm]:
		part.material_override = _material
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(part)
	visible = false

func set_tint(tint: Color) -> void:
	_material.set_shader_parameter("tint", tint)

func follow_wrist(hand: Vector3, plane: Basis, _outward: float, in_front: bool) -> void:
	_wrist = hand
	_plane = plane
	_front = in_front
	_has_wrist = true

func present(contact: Vector3) -> void:
	visible = _has_wrist
	if not visible: return
	# Keep the grip inside the palm; the view-facing shell covers the handle.
	global_transform = Transform3D(Basis.IDENTITY, contact)
	var wrist := _wrist + _plane.z * (0.035 if _front else -0.035)
	var reach := contact - wrist
	_arm.visible = reach.length() > 0.12
	if not _arm.visible: return
	var along := reach.normalized()
	var across := along.cross(_plane.z).normalized()
	if across.is_zero_approx(): across = _plane.x
	_arm.global_transform = Transform3D(Basis(across, along * reach.length(), across.cross(along)), (wrist + contact) * 0.5)
