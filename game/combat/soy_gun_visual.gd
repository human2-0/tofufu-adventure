class_name SoyGunVisual
extends Sprite3D
## Original sheets are retained; atlas regions exclude their printed captions.

const ABOVE = preload("res://assets/weapons/soy_gun/source/gun_above.png")
const REAR = preload("res://assets/weapons/soy_gun/source/gun_back.png")
const TOP_REGIONS: Array[Rect2] = [Rect2(30,275,205,443), Rect2(267,325,257,393), Rect2(534,348,380,370), Rect2(928,322,293,396), Rect2(1226,273,203,447)]
const REAR_REGIONS: Array[Rect2] = [Rect2(14,305,213,460), Rect2(233,310,300,455), Rect2(537,309,368,456), Rect2(913,308,307,457), Rect2(1224,305,207,460)]
var kick: float = 0.0
var _muzzle_pixel := Vector2.ZERO
var facing: Vector2 = Vector2.DOWN
var _hand := Vector3.ZERO
var _front: bool = true
var _atlas := AtlasTexture.new()

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.35
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	texture = _atlas
	visible = false

func follow_hand(hand: Vector3, _plane: Basis, _outward: float, in_front: bool) -> void:
	_hand = hand
	_front = in_front

func _process(delta: float) -> void:
	kick = move_toward(kick, 0.0, delta * 12.0)
	refresh()

func refresh() -> void:
	if not visible: return
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var world := Vector3(facing.x, 0, facing.y)
	var right := camera.global_basis.x
	var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var relative := Vector2(world.dot(right), world.dot(back))
	var octant := posmod(roundi(atan2(relative.x, -relative.y) / (PI / 4)), 8)
	var index := octant if octant <= 4 else 8 - octant
	var above := camera.global_basis.z.y > 0.5
	_atlas.atlas = ABOVE if above else REAR
	_atlas.region = (TOP_REGIONS if above else REAR_REGIONS)[index]
	var muzzle_points: Array[Vector2] = [Vector2(0.5, 0.48), Vector2(0.24, 0.48), Vector2(0.04, 0.4), Vector2(0.18, 0.48), Vector2(0.46, 0.48)]
	_muzzle_pixel = muzzle_points[index] * _atlas.region.size
	# Both sheets' side profile points left. Mirror the right-facing half.
	flip_h = octant > 0 and octant < 4
	pixel_size = 0.62 / _atlas.region.size.y
	var grip_x := 0.65 if index == 2 else 0.5
	offset = Vector2((0.5 - grip_x) * _atlas.region.size.x * (-1 if flip_h else 1), _atlas.region.size.y * 0.25)
	global_position = _hand + camera.global_basis.y * kick * 0.035 + camera.global_basis.z * kick * 0.025 + camera.global_basis.z * (0.035 if _front or index == 2 else -0.035)

func muzzle_position() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null or _atlas.region.size.is_zero_approx(): return global_position
	var point := _muzzle_pixel
	if flip_h: point.x = _atlas.region.size.x - point.x
	var local := Vector3(point.x - _atlas.region.size.x * 0.5 + offset.x, _atlas.region.size.y * 0.5 - point.y + offset.y, 0) * pixel_size
	return global_position + camera.global_basis.orthonormalized() * local
