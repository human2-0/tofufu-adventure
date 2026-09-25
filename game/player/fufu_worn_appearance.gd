class_name FufuWornAppearance
extends RefCounted
## Selects the supplied full-set walking, standing and jumping views.

const BRIGHT_WALK: Texture2D = preload("res://assets/characters/fufu/sets/bright_leaf_walk.png")
const DARK_WALK: Texture2D = preload("res://assets/characters/fufu/sets/dark_leaf_walk.png")
const BRIGHT_STANDING: Texture2D = preload("res://assets/characters/fufu/sets/bright_leaf_standing.png")
const DARK_STANDING: Texture2D = preload("res://assets/characters/fufu/sets/dark_leaf_standing.png")
const BRIGHT_JUMP: Texture2D = preload("res://assets/characters/fufu/sets/green_leaf_knight_jump_sprite_sheet.png")
const DARK_JUMP: Texture2D = preload("res://assets/characters/fufu/sets/dark_sprout_soldier_jump_sprite_sheet.png")
const STANDING_FEET: Array[float] = [724.0, 700.0, 689.0, 644.0, 708.0]
const DARK_STANDING_FEET: Array[float] = [724.0, 698.0, 706.0, 670.0, 724.0]
const WALK_COLUMN_STARTS: Array[int] = [27, 294, 560, 829]
const WALK_ROW_STARTS: Array[int] = [20, 280, 540, 800, 1055]
const WALK_CELL_SIZE := Vector2i(240, 260)
const BRIGHT_WALK_FEET: Array[float] = [242.0, 245.0, 241.0, 238.0, 241.0]
const DARK_WALK_FEET: Array[float] = [241.0, 242.0, 241.0, 239.0, 240.0]
const WALK_PIXEL_SIZE: float = 0.0049
const STANDING_PIXEL_SIZE: float = 0.002
const JUMP_PIXEL_SIZE: float = 0.0044
const JUMP_COLUMN_STARTS: Array[int] = [10, 265, 510, 750, 1005]
const JUMP_COLUMN_WIDTH: int = 245
# Each column has five painted row ranges. The supplied atlas does not use equal cells.
const BRIGHT_JUMP_BOUNDS := [
	[17, 263, 278, 530, 536, 787, 804, 1042, 1057, 1243],
	[13, 266, 278, 534, 547, 794, 809, 1051, 1060, 1244],
	[20, 264, 275, 543, 545, 799, 816, 1047, 1060, 1245],
	[21, 267, 282, 539, 549, 799, 813, 1050, 1061, 1244],
	[21, 266, 282, 536, 554, 803, 822, 1045, 1061, 1244],
]
const DARK_JUMP_BOUNDS := [
	[29, 268, 290, 528, 546, 788, 805, 1027, 1035, 1239],
	[31, 269, 292, 532, 544, 788, 807, 1026, 1038, 1240],
	[29, 268, 289, 530, 543, 782, 802, 1014, 1034, 1240],
	[32, 274, 291, 531, 546, 784, 807, 1025, 1038, 1243],
	[31, 274, 292, 530, 546, 787, 802, 1030, 1035, 1240],
]
const JUMP_ROWS_BY_PHASE: Array[int] = [0, 1, 2, 3, 3, 3, 4, 4, 4, 4]
const JUMP_HAND_HEIGHTS: Array[float] = [0.78, 0.70, 0.66, 0.64, 0.75]
var _jump_frames: Dictionary = {}
var _walk_frames: Dictionary = {}

func apply(sprite: Sprite3D, set_id: String, facing: int, walking: bool, walk_phase: int = 0) -> void:
	if walking:
		var direction_row := _standing_frame(facing)
		sprite.texture = _walk_frame(set_id, direction_row, posmod(walk_phase, 4))
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
		sprite.flip_h = facing in [3, 4, 5]
		sprite.pixel_size = WALK_PIXEL_SIZE
		var feet := BRIGHT_WALK_FEET if set_id == "bright_leaf" else DARK_WALK_FEET
		sprite.offset.y = feet[direction_row] - WALK_CELL_SIZE.y * 0.5 - 0.56 / WALK_PIXEL_SIZE
		return
	sprite.texture = BRIGHT_STANDING if set_id == "bright_leaf" else DARK_STANDING
	sprite.hframes = 5
	sprite.vframes = 1
	sprite.frame = _standing_frame(facing)
	sprite.flip_h = facing in [3, 4, 5]
	sprite.pixel_size = STANDING_PIXEL_SIZE
	var feet := STANDING_FEET if set_id == "bright_leaf" else DARK_STANDING_FEET
	sprite.offset.y = feet[sprite.frame] - sprite.texture.get_height() * 0.5 - 0.56 / sprite.pixel_size

func apply_jump(sprite: Sprite3D, set_id: String, facing: int, jump_phase: int) -> void:
	var direction_column := _standing_frame(facing)
	var animation_row := JUMP_ROWS_BY_PHASE[clampi(jump_phase, 0, JUMP_ROWS_BY_PHASE.size() - 1)]
	sprite.material_override = null
	sprite.texture = _jump_frame(set_id, animation_row, direction_column)
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.flip_h = facing in [3, 4, 5]
	sprite.pixel_size = JUMP_PIXEL_SIZE
	var bounds: Array = BRIGHT_JUMP_BOUNDS[direction_column] if set_id == "bright_leaf" else DARK_JUMP_BOUNDS[direction_column]
	var painted_bottom: int = bounds[animation_row * 2 + 1]
	var region := (sprite.texture as AtlasTexture).region
	sprite.offset = Vector2(0, painted_bottom - region.position.y - region.size.y * 0.5 - 0.56 / JUMP_PIXEL_SIZE)

func hand_point(sprite: Sprite3D, walking: bool, jumping: bool = false, jump_phase: int = -1) -> Vector2:
	var cell := Vector2(sprite.texture.get_size()) / Vector2(sprite.hframes, sprite.vframes)
	if jumping:
		var animation_row := JUMP_ROWS_BY_PHASE[clampi(jump_phase, 0, JUMP_ROWS_BY_PHASE.size() - 1)]
		return Vector2(cell.x * 0.78, cell.y * JUMP_HAND_HEIGHTS[animation_row])
	return Vector2(cell.x * 0.78, cell.y * (0.62 if walking else 0.67))

func _walk_frame(set_id: String, row: int, column: int) -> AtlasTexture:
	var key := "%s:%d:%d" % [set_id, row, column]
	if _walk_frames.has(key): return _walk_frames[key] as AtlasTexture
	var view := AtlasTexture.new()
	view.atlas = BRIGHT_WALK if set_id == "bright_leaf" else DARK_WALK
	view.region = Rect2(WALK_COLUMN_STARTS[column], WALK_ROW_STARTS[row], WALK_CELL_SIZE.x, WALK_CELL_SIZE.y)
	view.filter_clip = true
	_walk_frames[key] = view
	return view

func _jump_frame(set_id: String, row: int, column: int) -> AtlasTexture:
	var key := "%s:%d:%d" % [set_id, row, column]
	if _jump_frames.has(key):
		return _jump_frames[key] as AtlasTexture
	var view := AtlasTexture.new()
	view.atlas = BRIGHT_JUMP if set_id == "bright_leaf" else DARK_JUMP
	var bounds: Array = BRIGHT_JUMP_BOUNDS[column] if set_id == "bright_leaf" else DARK_JUMP_BOUNDS[column]
	var top: int = maxi(bounds[row * 2] - 2, bounds[(row - 1) * 2 + 1] + 1 if row > 0 else 0)
	var bottom: int = mini(bounds[row * 2 + 1] + 2, bounds[(row + 1) * 2] - 1 if row < 4 else 1253)
	view.region = Rect2(JUMP_COLUMN_STARTS[column], top, JUMP_COLUMN_WIDTH, bottom - top + 1)
	view.filter_clip = true
	_jump_frames[key] = view
	return view

func _standing_frame(facing: int) -> int:
	if facing == 6: return 0
	if facing in [5, 7]: return 1
	if facing in [0, 4]: return 2
	if facing in [1, 3]: return 3
	return 4
