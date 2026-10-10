class_name CloudResidentArt
extends Sprite3D
## Five authored views become eight observer-relative directions; angels also flutter.

const CELLS: Array[int] = [2, 3, 4, 3, 2, 1, 0, 1]
var asset: String = "guardian"
var height: float = 2.4
var facing := Vector2.DOWN
var view_focus: Node3D
var current_direction: int = -1
var current_cell: int = 4
var current_pose: int = -1
var elapsed: float = 0.0
var _frames: Array[AtlasTexture] = []
var _bounds: Array[Rect2] = []
var _anchors: Array[Vector2] = []
var _flip_cells: Array[int] = []

func _ready() -> void:
	name = "DirectionalArt"
	var entry := CloudSpriteCatalog.entry(asset)
	var sheet: Texture2D = entry.sheet
	_bounds.assign(entry.bounds)
	_anchors.assign(entry.anchors)
	_flip_cells.assign(entry.flip_cells)
	for index in _bounds.size():
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = CloudSpriteCatalog.crop(_bounds, index)
		frame.filter_clip = true
		_frames.append(frame)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.4
	shaded = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	present_direction(2)

func _process(delta: float) -> void:
	elapsed += delta
	var camera := get_viewport().get_camera_3d()
	if camera != null: update_view(camera)

func update_view(camera: Camera3D) -> void:
	var back := camera.global_position - global_position
	back.y = 0
	if back.length_squared() < 0.01 or back.length_squared() > 25600: return
	var forward := global_basis * Vector3(facing.x, 0, facing.y)
	if is_instance_valid(view_focus):
		var toward := view_focus.global_position - global_position
		toward.y = 0
		if toward.length_squared() > 0.01 and toward.length_squared() < 25: forward = toward.normalized()
	back = back.normalized()
	var side := Vector3(back.z, 0, -back.x)
	var direction := Vector2(forward.dot(side), forward.dot(back))
	present_direction(posmod(roundi(direction.angle() / (PI / 4.0)), 8))

func present_direction(direction: int) -> void:
	direction = posmod(direction, 8)
	var pose := int(elapsed * 5.0) % 2 if asset == "angel" else 0
	if direction == current_direction and pose == current_pose: return
	current_direction = direction
	current_pose = pose
	current_cell = CELLS[direction]
	flip_h = (direction in [3, 4, 5]) != (current_cell in _flip_cells)
	var index := current_cell + pose * 5
	texture = _frames[index]
	pixel_size = height / _bounds[current_cell].size.y
	var region := _frames[index].region
	var anchor := _anchors[index]
	var horizontal := region.get_center().x - anchor.x
	if flip_h: horizontal = -horizontal
	offset = Vector2(horizontal, anchor.y - region.get_center().y + 0.04 / pixel_size)

func set_focus_highlight(active: bool) -> void:
	modulate = Color(1.12, 1.08, 0.9) if active else Color.WHITE
