class_name LavaKingArt
extends Sprite3D
## Five authored views provide eight camera-relative angles and calibrated combat poses.

const TEXTURES: Array[Texture2D] = [
	preload("res://assets/characters/lava_king/lava-king-north.png"),
	preload("res://assets/characters/lava_king/lava-king-north-east.png"),
	preload("res://assets/characters/lava_king/lava-king-east.png"),
	preload("res://assets/characters/lava_king/lava-king-south-east.png"),
	preload("res://assets/characters/lava_king/lava-king-south.png")]
# Measured silhouettes at the alpha-cut threshold; source PNGs remain untouched.
const BOUNDS: Array[Rect2] = [Rect2(49, 49, 1207, 1082), Rect2(45, 40, 1251, 1076),
	Rect2(71, 42, 1192, 1093), Rect2(32, 24, 1258, 1146), Rect2(20, 37, 1200, 1148)]
const FOOT_X: Array[float] = [636, 780, 925, 835, 625]
const CELLS: Array[int] = [2, 3, 4, 3, 2, 1, 0, 1]
const HEIGHT: float = 3.05
@export var facing := Vector2.DOWN
var current_direction: int = -1
var current_cell: int = 4
var _frames: Array[AtlasTexture] = []
var _combat := KingCombatFrames.new()
var pose: String = "idle"
var elapsed: float = 0.0
var _pose_cell: int = -1

func _ready() -> void:
	name = "DirectionalArt"
	for index in TEXTURES.size():
		var frame := AtlasTexture.new()
		frame.atlas = TEXTURES[index]
		frame.region = BOUNDS[index].grow(8)
		_frames.append(frame)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.4
	shaded = false
	present_direction(2)

func _process(_delta: float) -> void:
	elapsed += _delta
	var camera := get_viewport().get_camera_3d()
	if camera != null: update_view(camera)

func update_view(camera: Camera3D) -> void:
	var forward := global_basis * Vector3(facing.x, 0, facing.y)
	# The observer ray changes even when the follow camera keeps a fixed orientation.
	var back := camera.global_position - global_position
	back.y = 0
	if back.length_squared() < 0.01: return
	back = back.normalized()
	var side := Vector3(back.z, 0, -back.x)
	var direction := Vector2(forward.dot(side), forward.dot(back))
	if direction.length_squared() < 0.01: return
	present_direction(posmod(roundi(direction.angle() / (PI / 4.0)), 8))

func present_direction(direction: int) -> void:
	direction = posmod(direction, 8)
	var pose_cell := _current_pose()
	if direction == current_direction and pose_cell == _pose_cell: return
	_pose_cell = pose_cell
	current_direction = direction
	current_cell = CELLS[direction]
	flip_h = direction in [3, 4, 5]
	if pose_cell >= 0:
		_combat.present(self, current_cell, pose_cell, flip_h, HEIGHT)
		return
	texture = _frames[current_cell]
	pixel_size = HEIGHT / BOUNDS[current_cell].size.y
	var region := _frames[current_cell].region
	var anchor_x := region.get_center().x - FOOT_X[current_cell]
	if flip_h: anchor_x = -anchor_x
	offset = Vector2(anchor_x, region.size.y * 0.5 - 8 + 0.05 / pixel_size)

func set_pose(value: String) -> void:
	pose = value

func _current_pose() -> int:
	match pose:
		"walk": return int(elapsed / 0.22) % 2
		"channel": return 2
		"release": return 3
		"hit": return 4
		"defeat": return 5
	return -1
