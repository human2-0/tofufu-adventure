class_name BattleHUDIcons
extends RefCounted
## Small ink-outlined symbols and numbers; HUD views receive display values only.
const HEART = preload("res://assets/ui/battle/heart.svg")
const ARMOR = preload("res://assets/ui/battle/armor.svg")
const ENERGY = preload("res://assets/ui/battle/energy.svg")
const ALIVE = preload("res://assets/ui/battle/alive.svg")
const KO = preload("res://assets/ui/battle/ko.svg")
const STORM = preload("res://assets/ui/battle/storm.svg")
const SAFE = preload("res://assets/ui/battle/safe.svg")
const CHEST = preload("res://assets/ui/battle/chest.svg")
const CLOCK = preload("res://assets/ui/battle/clock.svg")
const INK := Color("102d28eb")
const WHITE := Color("edf5de")

static func number(view: Control, at: Vector2, text: String, font_size: int = 16, color: Color = WHITE) -> void:
	view.draw_string(ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

static func panel(view: Control, rect: Rect2) -> void:
	var style := MenuStyle.panel(INK, 9)
	style.set_content_margin_all(0)
	style.border_color = Color("a9cfac65")
	view.draw_style_box(style, rect)

static func icon(view: Control, texture: Texture2D, at: Vector2, extent: float = 20, tint: Color = Color.WHITE) -> void:
	if texture == null: return
	view.draw_texture_rect(texture, Rect2(at, Vector2.ONE * extent), false, tint)

static func bar(view: Control, rect: Rect2, tint: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(3)
	view.draw_style_box(style, rect)
