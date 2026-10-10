class_name MeadowResidentArt
extends Sprite3D
## Local eight-way camera-relative presentation of stationary Fufu residents.

var asset: String = "grandma"
var facing := Vector2.DOWN
var view_focus: Node3D
const CELLS: Array[int] = [2, 3, 4, 3, 2, 1, 0, 1]
var current_direction: int = -1
var current_cell: int = 4
var _frames: Array[AtlasTexture] = []

func _ready() -> void:
	name = "DirectionalArt"
	var sheet: Texture2D = load("res://assets/characters/village/" + asset + "-directions.png")
	for bounds in _bounds():
		var cell := AtlasTexture.new()
		cell.atlas = sheet
		cell.region = bounds.grow(8)
		_frames.append(cell)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.4
	shaded = false
	present_direction(2)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var look := facing
	if is_instance_valid(view_focus):
		var offset := view_focus.global_position - global_position
		var toward := Vector2(offset.x, offset.z)
		if toward.length_squared() > 0.01 and toward.length_squared() < 16: look = toward.normalized()
	var world := Vector3(look.x, 0, look.y)
	var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var direction := Vector2(world.dot(camera.global_basis.x), world.dot(back))
	if direction.length_squared() < 0.01: return
	present_direction(posmod(roundi(direction.angle() / (PI / 4.0)), 8))

func present_direction(direction: int) -> void:
	if direction == current_direction: return
	current_direction = direction
	current_cell = CELLS[direction]
	# Generated SE portraits look left; mirror them to agree with E/NE.
	flip_h = (direction in [3, 4, 5]) != (current_cell == 3)
	texture = _frames[current_cell]
	var height := _bounds()[current_cell].size.y
	pixel_size = 1.65 / height
	offset = Vector2(0, height * 0.5 + 0.05 / pixel_size)

func _bounds() -> Array[Rect2]:
	# Measured alpha silhouettes, preserving every source pixel and safe margins.
	if asset == "grandma":
		return [Rect2(36, 67, 389, 612), Rect2(484, 71, 355, 611), Rect2(890, 64, 356, 621), Rect2(1282, 70, 424, 617), Rect2(1745, 72, 396, 614)]
	return [Rect2(24, 56, 397, 608), Rect2(495, 71, 365, 597), Rect2(921, 65, 302, 603), Rect2(1303, 62, 373, 610), Rect2(1751, 63, 401, 602)]
