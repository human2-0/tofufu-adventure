class_name FufuUnarmedArt
extends RefCounted
## Painted whole-body contacts selected by the injected cosmetic strike context.

const DIRECTORY := "res://assets/characters/fufu/unarmed/"
const ROWS: Array[int] = [2, 1, 0, 1, 2, 3, 4, 3]
var hand := Vector2.ZERO
var style: int = -1
var _layout: Dictionary = {}
var _textures: Dictionary = {}

func apply(sprite: FufuVisuals, context: Dictionary) -> bool:
	style = int(context.get("style", -1))
	if style < 0 or style > 3: return false
	var elapsed := float(context.get("elapsed", INF))
	var duration := float(context.get("duration", 0.0))
	if elapsed < 0.0 or elapsed >= duration: return false
	if _layout.is_empty():
		_layout = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "layout.json")) as Dictionary
	var outfit := "base" if sprite.worn_set.is_empty() else sprite.worn_set
	var row := ROWS[int(sprite.current_facing)]
	var data: Dictionary = _layout[outfit][row * 4 + style]
	var key := "%s:%d:%d" % [outfit, row, style]
	if not _textures.has(key):
		var view := AtlasTexture.new()
		view.atlas = load(DIRECTORY + outfit + ".png") as Texture2D
		var region: Array = data.region
		view.region = Rect2(region[0], region[1], region[2], region[3])
		view.filter_clip = true
		_textures[key] = view
	sprite.texture = _textures[key] as AtlasTexture
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.material_override = null
	sprite.flip_h = (int(sprite.current_facing) in [0, 1, 7]) != bool(data.get("source_flip", false))
	sprite.pixel_size = float(data.pixel_size)
	var size := sprite.texture.get_size()
	var center := size.x * 0.5 - float(data.center)
	sprite.offset = Vector2(-center if sprite.flip_h else center, float(data.feet) - size.y * 0.5 - 0.56 / sprite.pixel_size)
	var point: Array = data.left_hand if sprite.flip_h else data.hand
	hand = Vector2(point[0], point[1])
	return true

func follow_through(sprite: FufuVisuals, context: Dictionary) -> void:
	var progress := clampf(float(context.elapsed) / float(context.duration), 0.0, 1.0)
	var weight := sin(progress * PI)
	sprite.scale = Vector3(1.0 + weight * 0.06, 1.0 - weight * 0.04, 1.0)
	# Squash around the planted foot, preserving the source's ground registration.
	sprite.offset.y += 0.56 * (1.0 - 1.0 / sprite.scale.y) / sprite.pixel_size
