class_name DofufuCityArt
extends Sprite3D
## Five complete authored views mirrored into eight camera-relative directions.

const SHEET: Texture2D = preload("res://assets/characters/dofufu_city/city-directions.png")
const ROWS: Array[int] = [0, 263, 520, 772, 1024]
const SOLES: Array[int] = [258, 518, 768, 1018]
const CELLS: Array[int] = [2, 1, 0, 1, 2, 3, 4, 3]
var role: int = 0
var height: float = 1.9
var facing := Vector2.DOWN
var current_cell: int = -1
var _frames: Array[AtlasTexture] = []

func _ready() -> void:
	for column in 5:
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = SHEET
		atlas_frame.region = Rect2(roundf(column * 307.2), ROWS[role], 307, ROWS[role + 1] - ROWS[role])
		atlas_frame.filter_clip = true
		_frames.append(atlas_frame)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.3
	shaded = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pixel_size = height / float(SOLES[role] - ROWS[role])
	offset.y = float(SOLES[role] - ROWS[role]) - texture_height() * 0.5
	present_direction(2)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	var toward := camera.global_position - global_position
	toward.y = 0
	if toward.length_squared() < 0.01 or toward.length_squared() > 14400: return
	var front := global_basis * Vector3(facing.x, 0, facing.y)
	var back := toward.normalized()
	var side := Vector3(back.z, 0, -back.x)
	var view := Vector2(front.dot(side), front.dot(back))
	present_direction(posmod(roundi(view.angle() / (PI / 4)), 8))

func present_direction(direction: int) -> void:
	current_cell = CELLS[posmod(direction, 8)]
	flip_h = direction in [3, 4, 5]
	texture = _frames[current_cell]

func texture_height() -> float:
	return float(ROWS[role + 1] - ROWS[role])
