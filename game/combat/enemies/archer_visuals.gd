class_name ArcherVisuals
extends Sprite3D
## Eight observer-relative travel facings, two strides, and original bow draw poses.

const WALK: Texture2D = preload("res://assets/characters/groatfields/archer-walk-eight.png")
const BOW: Texture2D = preload("res://assets/characters/groatfields/archer.png")
const WALK_REGIONS: Array[Rect2] = [
	Rect2(34, 21, 292, 274), Rect2(366, 24, 275, 272),
	Rect2(664, 23, 216, 273), Rect2(968, 22, 267, 272),
	Rect2(23, 318, 292, 273), Rect2(358, 320, 273, 270),
	Rect2(681, 319, 216, 273), Rect2(986, 317, 266, 275),
	Rect2(27, 626, 297, 272), Rect2(360, 634, 282, 264),
	Rect2(664, 628, 227, 270), Rect2(965, 629, 277, 269),
	Rect2(25, 917, 289, 279), Rect2(357, 919, 274, 276),
	Rect2(687, 922, 223, 274), Rect2(978, 914, 273, 282),
]
const CENTERS: Array[float] = [179, 490, 809, 1105, 168, 489, 822, 1128, 174, 489, 811, 1108, 167, 489, 827, 1123]
# Match west views by mirroring the corresponding right-facing authored view.
const TRAVEL_FRAMES: Array[int] = [0, 7, 6, 5, 4, 5, 6, 7]
const DRAW_FRAMES: Array[int] = [0, 0, 3, 1, 1, 1, 2, 0]
const DRAW_REGIONS: Array[Rect2] = [
	Rect2(32, 400, 433, 360), Rect2(468, 400, 457, 360),
	Rect2(1035, 400, 473, 360), Rect2(1510, 400, 445, 360),
]
var elapsed: float = 0.0
var direction_index: int = 0
var walk_phase: int = 0
var _travel: Array[AtlasTexture] = []
var _draw: Array[AtlasTexture] = []

func _ready() -> void:
	for region in WALK_REGIONS: _travel.append(_frame(WALK, region))
	for region in DRAW_REGIONS: _draw.append(_frame(BOW, region))
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	present(Vector3.BACK, 0.0, 0.0)

func _frame(atlas: Texture2D, region: Rect2) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = atlas
	result.region = region
	result.filter_clip = true
	return result

func present(facing: Vector3, windup: float, delta: float, moving: bool = false) -> void:
	elapsed += delta
	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.BACK if camera == null else camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	var angle := atan2(facing.dot(right), facing.dot(forward))
	direction_index = posmod(-roundi(angle / (PI / 4.0)), 8)
	if windup > 0.0:
		texture = _draw[DRAW_FRAMES[direction_index]]
		pixel_size = 2.8 / (BOW.get_height() / 2.0)
		flip_h = false
		offset = Vector2.ZERO
	else:
		walk_phase = int(elapsed * 6.0) % 2 if moving else 0
		var index := TRAVEL_FRAMES[direction_index] + walk_phase * 8
		var region := WALK_REGIONS[index]
		texture = _travel[index]
		pixel_size = 2.4 / 267.0
		flip_h = direction_index in [1, 2, 3]
		offset.x = (region.size.x * 0.5 - (CENTERS[index] - region.position.x)) * (-1 if flip_h else 1)
		offset.y = region.size.y - 4 - region.size.y * 0.5 - 1.23 / pixel_size
	position.y = 1.35 + (absf(sin(elapsed * 10.0)) * 0.04 if moving else sin(elapsed * 3) * 0.025)
	modulate = modulate.lerp(Color.WHITE, minf(1, delta * 8))
