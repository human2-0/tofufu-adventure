class_name TofufuTestArt
extends RefCounted
## Session-only cosmetic atlas selection. Never changes equipment or actor rules.

const ROOT := "res://assets/characters/tofufu/"
const IDS := ["crispy_tofufu", "smoked_tofufu_green_headband", "panko_tofufu", "golden_tofufu", "smoked_tofufu_steam", "silken_tofufu", "burnt_tofufu"]
const NAMES := ["Crispy Tofufu", "Firm Tofufu", "Panko Tofufu", "Golden Tofufu", "Smoked Tofufu · Steam", "Silken Tofufu", "Burnt Tofufu"]
const ROWS := [2, 3, 4, 3, 2, 1, 0, 1]
var selected: String = ""
var hand := Vector2.ZERO
var kind: String = "locomotion"
var phase: int = 0
var _layout: Dictionary = {}
var _textures: Dictionary = {}

func active() -> bool:
	return not selected.is_empty()

func select(id: String) -> bool:
	if not id.is_empty() and id not in IDS: return false
	selected = id
	_textures.clear()
	_layout = {} if id.is_empty() else JSON.parse_string(FileAccess.get_file_as_string(ROOT + id + "/sprite-layout.json")) as Dictionary
	return true

func present(sprite: FufuVisuals, walking: bool, grounded: bool, dashing: bool, charge: float, strike: Dictionary) -> bool:
	var contact := false
	kind = "locomotion"
	phase = sprite.anim_frame + 1 if walking else 0
	if sprite.jump_animation.frame >= 0 or charge > 0.0:
		kind = "jump"
		phase = maxi(0, sprite.jump_animation.frame)
	elif grounded and not dashing and not strike.is_empty():
		var style := int(strike.get("style", -1))
		contact = style in [0, 1, 2, 3] and float(strike.get("elapsed", INF)) >= 0.0 and float(strike.get("elapsed", INF)) < float(strike.get("duration", 0.0))
		if contact:
			kind = "melee"
			phase = style
	apply(sprite, kind, phase)
	return contact

func apply(sprite: FufuVisuals, category: String, column: int) -> void:
	var row: int = ROWS[int(sprite.current_facing)]
	var columns := 5 if category == "locomotion" else (10 if category == "jump" else 4)
	var data: Dictionary = _layout.sheets[category][row * columns + column]
	var key := "%s:%d:%d" % [category, row, column]
	if not _textures.has(key):
		var view := AtlasTexture.new()
		view.atlas = load(ROOT + selected + "/" + category + ".png") as Texture2D
		var region: Array = data.region
		view.region = Rect2(region[0], region[1], region[2], region[3])
		view.filter_clip = true
		_textures[key] = view
	sprite.texture = _textures[key] as AtlasTexture
	sprite.material_override = null
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.flip_h = int(sprite.current_facing) in [0, 1, 7]
	sprite.pixel_size = float(data.pixel_size)
	var size := sprite.texture.get_size()
	var center := size.x * 0.5 - float(data.center)
	sprite.offset = Vector2(-center if sprite.flip_h else center, float(data.feet) - size.y * 0.5 - 0.56 / sprite.pixel_size)
	var bounds: Array = data.painted_bounds
	var wrist_x: float = [0.73, 0.73, 0.32, 0.27, 0.26][row]
	if sprite.flip_h: wrist_x = 1.0 - wrist_x
	var wrist_y := 0.43 if category == "melee" and column == 2 else 0.65
	if category == "jump" and column in [1, 2, 3, 4]: wrist_y = 0.48
	hand = Vector2(float(bounds[0]) + float(bounds[2]) * wrist_x, float(bounds[1]) + float(bounds[3]) * wrist_y)

func tint() -> Color:
	if selected == "burnt_tofufu": return Color("533c2e")
	return Color("ffc640") if selected in ["crispy_tofufu", "golden_tofufu"] else Color("fff0bd")

static func thumbnail(id: String) -> Texture2D:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + id + "/sprite-layout.json")) as Dictionary
	var region: Array = data.sheets.locomotion[20].region
	var view := AtlasTexture.new()
	view.atlas = load(ROOT + id + "/locomotion.png") as Texture2D
	view.region = Rect2(region[0], region[1], region[2], region[3])
	view.filter_clip = true
	return view
