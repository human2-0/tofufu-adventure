class_name MountainHybridArt
extends Sprite3D
## Five full silhouettes, calibrated to the generated sheet's transparent gutters.

const SHEET: Texture2D = preload("res://assets/characters/mountain_hybrid/hermit-directions.png")
const REGIONS: Array[Rect2] = [Rect2(0, 300, 337, 400), Rect2(337, 300, 312, 400), Rect2(649, 300, 255, 400), Rect2(904, 300, 300, 400), Rect2(1204, 300, 332, 400)]
const CELLS: Array[int] = [2, 1, 0, 1, 2, 3, 4, 3]
var facing := Vector2.DOWN
var current_cell: int = 0
var _frames: Array[AtlasTexture] = []

func _ready() -> void:
	for region in REGIONS:
		var frame := AtlasTexture.new()
		frame.atlas = SHEET
		frame.region = region
		frame.filter_clip = true
		_frames.append(frame)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.3
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shaded = false
	pixel_size = 0.0058
	offset.y = 180
	present_direction(2)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var toward := camera.global_position - global_position
	toward.y = 0
	if toward.length_squared() < 0.01 or toward.length_squared() > 6400: return
	var front := Vector3(facing.x, 0, facing.y)
	var back := toward.normalized()
	var side := Vector3(back.z, 0, -back.x)
	var view := Vector2(front.dot(side), front.dot(back))
	present_direction(posmod(roundi(view.angle() / (PI / 4)), 8))

func present_direction(direction: int) -> void:
	current_cell = CELLS[posmod(direction, 8)]
	# The generated intermediate views face left; mirror them for the east views.
	flip_h = direction in [0, 1, 7]
	texture = _frames[current_cell]
