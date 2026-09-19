class_name SotjetVisual
extends Sprite3D
## Ten generated views: five directions, two camera elevations; mirrored to eight.

const ATLAS = preload("res://assets/weapons/sotjet/source/sotjet-atlas.png")
# Pixel landmarks on the original 1983x793 atlas, normalized within each cell.
const MUZZLES: Array[Vector2] = [Vector2(0.45,0.12), Vector2(0.15,0.13), Vector2(0.045,0.5), Vector2(0.23,0.65), Vector2(0.55,0.67), Vector2(0.45,0.29), Vector2(0.11,0.28), Vector2(0.045,0.4), Vector2(0.23,0.37), Vector2(0.55,0.4)]
const GRIPS: Array[Vector2] = [Vector2(0.45,0.64), Vector2(0.52,0.68), Vector2(0.68,0.72), Vector2(0.63,0.67), Vector2(0.55,0.72), Vector2(0.45,0.63), Vector2(0.52,0.65), Vector2(0.68,0.63), Vector2(0.63,0.63), Vector2(0.55,0.68)]
var facing := Vector2.DOWN
var _hand := Vector3.ZERO
var _front: bool = true

func _ready() -> void:
	texture = ATLAS
	hframes = 5
	vframes = 2
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/combat/sotjet_visual.gdshader")
	material.set_shader_parameter("atlas", ATLAS)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false

func follow_hand(hand: Vector3, _plane: Basis, _outward: float, in_front: bool) -> void:
	_hand = hand
	_front = in_front

func _process(_delta: float) -> void: refresh()

func refresh() -> void:
	if not visible: return
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var world := Vector3(facing.x, 0, facing.y)
	var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var relative := Vector2(world.dot(camera.global_basis.x), world.dot(back))
	var octant := posmod(roundi(atan2(relative.x, -relative.y) / (PI / 4)), 8)
	var index := octant if octant <= 4 else 8 - octant
	frame = index + (0 if camera.global_basis.z.y > 0.5 else 5)
	flip_h = octant > 0 and octant < 4
	var cell := Vector2(ATLAS.get_size()) / Vector2(5, 2)
	pixel_size = 0.72 / cell.y
	var grip := GRIPS[frame]
	if flip_h: grip.x = 1.0 - grip.x
	offset = Vector2((0.5 - grip.x) * cell.x, (grip.y - 0.5) * cell.y)
	global_position = _hand + camera.global_basis.z * (0.035 if _front or index == 2 else -0.035)

func muzzle_position() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return global_position
	var cell := Vector2(ATLAS.get_size()) / Vector2(5, 2)
	var point := MUZZLES[frame] * cell
	if flip_h: point.x = cell.x - point.x
	var local := Vector3(point.x - cell.x * 0.5 + offset.x, cell.y * 0.5 - point.y + offset.y, 0) * pixel_size
	return global_position + camera.global_basis.orthonormalized() * local
