class_name CelestialFufuArt
extends RefCounted
## Original RGBA atlases viewed through calibrated, non-destructive frame regions.

const DIRECTORY: String = "res://assets/characters/fufu/celestial/"
var hand := Vector2.ZERO
var action: String = "idle"
var phase: int = 0
var _layout: Dictionary = {}
var _textures: Dictionary = {}
var _dash_time: float = 0.0
var _charge_time: float = 0.0

func present(sprite: FufuVisuals, walking: bool, grounded: bool, dashing: bool, charge: float, delta: float, context: Dictionary) -> void:
	_dash_time = _dash_time + delta if dashing else 0.0
	_charge_time = _charge_time + delta if charge > 0.0 else 0.0
	var selected: String = str(context.get("action", ""))
	var frame_index: int = int(context.get("phase", 0))
	if selected not in ["riding", "hurt"]:
		if dashing:
			selected = "dash"
			frame_index = mini(int(_dash_time * 24.0), 3)
		elif grounded and charge > 0.0:
			selected = "charge"
			frame_index = int(_charge_time * 9.0) % 4
		elif sprite.jump_animation.frame >= 0:
			selected = "jump"
			frame_index = sprite.jump_animation.frame
		elif selected.is_empty() or (selected == "aim" and walking):
			selected = "walk" if walking else "idle"
			frame_index = sprite.anim_frame if walking else 0
	apply(sprite, int(sprite.current_facing), selected, frame_index)

func apply(sprite: Sprite3D, facing: int, selected: String, frame_index: int = 0) -> void:
	if _layout.is_empty():
		_layout = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + "sprite-layout.json")) as Dictionary
	action = selected
	phase = frame_index
	var frames: Array = _layout[selected][str(facing)]
	var data: Dictionary = frames[clampi(frame_index, 0, frames.size() - 1)]
	var key := "%s:%d:%d" % [selected, facing, clampi(frame_index, 0, frames.size() - 1)]
	if not _textures.has(key):
		var view := AtlasTexture.new()
		view.atlas = load(DIRECTORY + str(data.path)) as Texture2D
		var region: Array = data.region
		view.region = Rect2(region[0], region[1], region[2], region[3])
		view.filter_clip = true
		_textures[key] = view
	if sprite.texture != _textures[key]: sprite.texture = _textures[key] as AtlasTexture
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.flip_h = false
	sprite.material_override = null
	sprite.pixel_size = float(data.pixel_size)
	var size := sprite.texture.get_size()
	sprite.offset = Vector2(size.x * 0.5 - float(data.center), float(data.feet) - size.y * 0.5 - 0.56 / sprite.pixel_size)
	var point: Array = data.hand
	hand = Vector2(point[0], point[1])
