class_name SwordVisual
extends Node3D
## Supplied 3D blade art follows the same physical pose as the melee hit volume.

signal model_changed

var grip := WeaponGripVisual.new()
var nori: bool = false
var pod: bool = false
var tuning: CombatTuning
var debug_visible: bool = false
var _debug: MeshInstance3D
var _model_root: Node3D
var _model_instance: Node3D
var _charge_glow: StandardMaterial3D
var _model_id: String = ""
var _model_grip: Vector3 = Vector3.ZERO
var _physical_pose: Transform3D
var _hand: Vector3
var _hand_plane: Basis
var _outward: float = 1.0
var _in_front: bool = false
var _attachment: float = 0.0
var _has_hand: bool = false
var _has_pose: bool = false

func _ready() -> void:
	add_child(grip)
	_model_root = Node3D.new()
	add_child(_model_root)
	_charge_glow = StandardMaterial3D.new()
	_charge_glow.albedo_color = Color(1.0, 0.83, 0.45, 0.4)
	_charge_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_charge_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_charge_glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	_debug = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(tuning.blade_width, tuning.blade_thickness, tuning.blade_length)
	var tint := StandardMaterial3D.new()
	tint.albedo_color = Color(0.1, 1, 0.4, 0.3)
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = tint
	_debug.mesh = box
	_debug.visible = false
	add_child(_debug)
	_refresh_model()

func set_pod(value: bool) -> void:
	if pod == value: return
	pod = value
	_refresh_model()

func set_nori(value: bool) -> void:
	if nori == value: return
	nori = value
	_refresh_model()

func present(pose: Transform3D, _aim: Vector2, charge: float, cutting: bool = false, attachment: float = 0.0) -> void:
	_physical_pose = pose
	_attachment = 0.0 if cutting else clampf(attachment, 0.0, 1.0)
	_has_pose = true
	_apply_pose()
	_debug.visible = debug_visible and cutting
	var length := tuning.nori_length if nori else (tuning.pod_length if pod else tuning.blade_length)
	if _debug.visible:
		(_debug.mesh as BoxMesh).size = Vector3(tuning.pod_width if pod else tuning.blade_width, tuning.blade_thickness, length)
	_debug.global_transform = pose.translated_local(Vector3(0, 0, -length * 0.5))
	_set_charge(charge >= 1.0)

func follow_hand(hand: Vector3, plane: Basis, outward: float, in_front: bool) -> void:
	grip.follow_wrist(hand, plane, outward, in_front)
	_hand = hand
	_hand_plane = plane
	_outward = outward
	_in_front = in_front
	_has_hand = true
	if _has_pose:
		_apply_pose()

func model_tip_position() -> Vector3:
	if _model_instance == null: return Vector3.ZERO
	return _model_instance.to_global(WeaponModelCatalog.tip(_model_id))

func model_guard_position() -> Vector3:
	if _model_instance == null: return Vector3.ZERO
	return _model_instance.to_global(WeaponModelCatalog.GUARDS[_model_id])

func model_grip_position() -> Vector3:
	if _model_instance == null: return Vector3.ZERO
	return _model_instance.to_global(_source_grip())

func _refresh_model() -> void:
	if _model_root == null: return
	var item_id := "nori_katana" if nori else ("edamame_sword" if pod else "knife")
	if item_id == _model_id: return
	if _model_instance != null:
		_model_root.remove_child(_model_instance)
		_model_instance.free()
	_model_id = item_id
	var packed := WeaponModelCatalog.scene_for(item_id)
	if packed == null: return
	_model_instance = packed.instantiate() as Node3D
	_model_root.add_child(_model_instance)
	_model_instance.transform = WeaponModelCatalog.calibration(item_id, _blade_length())
	_model_grip = WeaponModelCatalog.grip_local(item_id, _blade_length())
	_set_shadows(_model_instance)
	model_changed.emit()

func _blade_length() -> float:
	return tuning.nori_length if nori else (tuning.pod_length if pod else tuning.blade_length)

func _source_grip() -> Vector3:
	return WeaponModelCatalog.GRIPS.get(_model_id, Vector3.ZERO)

func _set_charge(active: bool) -> void:
	if _model_instance == null: return
	_set_overlay(_model_instance, _charge_glow if active else null)

func _set_overlay(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_overlay = material
	for child in node.get_children(): _set_overlay(child, material)

func _set_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): _set_shadows(child)

func _apply_pose() -> void:
	_model_root.global_transform = _physical_pose
	if not _has_hand or _attachment <= 0.0:
		grip.present(model_grip_position())
		return
	var blade := (_hand_plane.y + _hand_plane.x * _outward * 0.55).normalized()
	var width := blade.cross(_hand_plane.z).normalized()
	var basis := Basis(width, -blade.cross(width), -blade)
	var depth := 0.035 if _in_front else -0.035
	var held := Transform3D(basis, _hand + _hand_plane.z * depth - basis * _model_grip)
	_model_root.global_transform = _physical_pose.interpolate_with(held, _attachment)
	grip.present(model_grip_position())
