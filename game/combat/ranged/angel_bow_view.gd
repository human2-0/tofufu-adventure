class_name AngelBowView
extends Node3D
## Eight-direction physical bow attached to the same wrist as other weapons.

var bow: AngelBow
var model: AngelBowModel
var grip := WeaponGripVisual.new()
var facing := Vector2.DOWN
var kick: float = 0.0
var _hand := Vector3.ZERO

func _ready() -> void:
	add_child(grip)
	model = AngelBowModel.new()
	add_child(model)
	hide()

func follow_hand(hand: Vector3, plane: Basis, outward: float, in_front: bool) -> void:
	_hand = hand
	grip.follow_wrist(hand, plane, outward, in_front)

func _process(delta: float) -> void:
	if not visible: return
	kick = move_toward(kick, 0.0, delta * 5)
	var forward := Vector3(facing.x, 0, facing.y)
	if forward.is_zero_approx(): forward = Vector3.BACK
	global_basis = Basis.looking_at(forward)
	global_position = _hand - forward * kick * 0.04
	var reloading := bow.reload_remaining > 0.0
	if reloading:
		global_basis *= Basis(Vector3.FORWARD, sin(bow.reload_remaining / AngelBow.RELOAD * PI) * 0.45)
	model.present(bow.charge / AngelBow.CHARGE, not reloading or bow.reload_remaining < 0.5)
	grip.present(global_position)
