class_name SotjetVisual
extends Node3D
## Supplied 3D Soyjet art follows the hand and reports its actual nozzle position.

var grip := WeaponGripVisual.new()
var facing := Vector2.DOWN
var first_person_view: bool = false
var run_lowering: float = 0.0
var _hand := Vector3.ZERO
var _front: bool = true
var _model: Node3D
var _model_reach: float = 0.62

func _ready() -> void:
	add_child(grip)
	_model = WeaponModelCatalog.SOYJET.instantiate() as Node3D
	add_child(_model)
	_model.transform = WeaponModelCatalog.calibration("sotjet", _model_reach)
	_set_shadows(_model)
	refresh()

func follow_hand(hand: Vector3, _plane: Basis, _outward: float, in_front: bool) -> void:
	grip.follow_wrist(hand, _plane, _outward, in_front)
	_hand = hand
	_front = in_front

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if _model == null: return
	_model.visible = visible
	if not visible: return
	if first_person_view:
		transform = Transform3D(Basis(Vector3.UP, 0.4), Vector3(0.14, -0.1, 0.0))
		return
	var forward := Vector3(facing.x, 0, facing.y).normalized()
	if forward.is_zero_approx(): forward = Vector3.BACK
	var basis := Basis.looking_at(forward, Vector3.UP)
	basis *= Basis(Vector3.RIGHT, -0.24 * run_lowering)
	var camera := get_viewport().get_camera_3d()
	var depth := 0.035 if _front else -0.035
	var position := _hand
	if camera != null: position += camera.global_basis.z * depth
	global_transform = Transform3D(basis, position)
	grip.present(model_grip_position())

func model_grip_position() -> Vector3:
	return _model.to_global(WeaponModelCatalog.GRIPS["sotjet"])

func muzzle_position() -> Vector3:
	if _model == null: return global_position
	return _model.to_global(WeaponModelCatalog.tip("sotjet"))

func _set_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children(): _set_shadows(child)
