class_name FufuChargeAnimation
extends RefCounted
## Authored atlas regions exclude the source labels without modifying its pixels.

const SOURCE: Texture2D = preload("res://assets/characters/fufu/soybean_fufu-charge-walk-source.png")
# Facing E, SE, S, SW, W, NW, N, NE. Rear diagonals retain existing art.
const ROWS: Array[int] = [2, 0, 1, 0, 2, -1, 3, -1]
const PIXEL_SIZE: float = 0.005
const REGIONS: Array[Rect2] = [
	Rect2(208, 16, 186, 234),
	Rect2(438, 15, 186, 234),
	Rect2(666, 14, 191, 236),
	Rect2(888, 14, 179, 234),
	Rect2(1108, 13, 183, 235),
	Rect2(1325, 15, 186, 236),
	Rect2(204, 282, 182, 209),
	Rect2(431, 282, 182, 215),
	Rect2(660, 281, 178, 217),
	Rect2(886, 280, 176, 217),
	Rect2(1108, 282, 176, 216),
	Rect2(1330, 281, 177, 217),
	Rect2(202, 520, 152, 238),
	Rect2(422, 519, 156, 238),
	Rect2(659, 520, 162, 238),
	Rect2(877, 520, 153, 235),
	Rect2(1104, 519, 151, 240),
	Rect2(1327, 519, 153, 237),
	Rect2(187, 775, 183, 208),
	Rect2(423, 778, 182, 209),
	Rect2(644, 774, 183, 212),
	Rect2(875, 775, 181, 211),
	Rect2(1105, 776, 181, 208),
	Rect2(1328, 774, 180, 211)]
var _textures: Array[AtlasTexture] = []
var hand: Vector2 = Vector2.ZERO

func _init() -> void:
	for region in REGIONS:
		var view := AtlasTexture.new()
		view.atlas = SOURCE
		view.region = region
		view.filter_clip = true
		_textures.append(view)

func apply(sprite: Sprite3D, facing: int, column: int) -> bool:
	var row := ROWS[facing]
	if row < 0:
		return false
	var view := _textures[row * 6 + posmod(column, 6)]
	sprite.texture = view
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.flip_h = facing in [0, 1]
	sprite.pixel_size = PIXEL_SIZE
	var size := Vector2(view.get_size())
	sprite.offset = Vector2(0, size.y * 0.5 - 3.0 - 0.56 / PIXEL_SIZE)
	match row:
		0: hand = Vector2(25, size.y - 67)
		1: hand = Vector2(size.x - 41, size.y - 56)
		2: hand = Vector2(48, size.y - 66)
		3: hand = Vector2(size.x - 25, size.y - 53)
	return true
