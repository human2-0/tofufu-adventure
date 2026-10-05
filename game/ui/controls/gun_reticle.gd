class_name GunReticle
extends Control

var spread_multiplier: float = 1.0
var precise: bool = false
var recoil: float = 0.0
var centered: bool = false
var aim_offset := Vector2.ZERO
var reload_remaining: float = 0.0
var reload_progress: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var center := get_viewport_rect().size * 0.5 if centered else get_viewport().get_mouse_position()
	if centered: center += aim_offset * get_viewport_rect().size
	if reload_remaining > 0.0:
		_draw_reload(center)
		return
	var radius := ((4.0 if precise else 18.0) + recoil * 18.0) * spread_multiplier
	var color := Color("fff5b7") if precise else Color(1, 1, 1, 0.8)
	draw_arc(center, radius, 0, TAU, 40, Color(0.08, 0.12, 0.08, 0.8), 4, true)
	draw_arc(center, radius, 0, TAU, 40, color, 1.5, true)
	draw_circle(center, 1.5, color)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(center + direction * (radius + 3), center + direction * (radius + 8), color, 2, true)

func _draw_reload(center: Vector2) -> void:
	var color := Color("ffd078")
	draw_circle(center, 1.5, color)
	draw_arc(center, 24.0, 0, TAU, 64, Color(0.08, 0.12, 0.08, 0.85), 6, true)
	if reload_progress > 0.001:
		draw_arc(center, 24.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(reload_progress, 0, 1), 64, color, 3, true)
	var font := ThemeDB.fallback_font
	var text := "RELOADING %.1fs" % reload_remaining
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
	# Keep the countdown on screen even when overhead aim is near an edge.
	var size := get_viewport_rect().size
	var at := Vector2(clampf(center.x - text_size.x * 0.5, 8, maxf(8, size.x - text_size.x - 8)), clampf(center.y + 47, 20, size.y - 8))
	draw_rect(Rect2(at + Vector2(-6, -18), text_size + Vector2(12, 6)), Color(0.06, 0.09, 0.07, 0.9))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)
