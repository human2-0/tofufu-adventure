class_name GunReticle
extends Control

var precise: bool = false
var recoil: float = 0.0
var centered: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var center := get_viewport_rect().size * 0.5 if centered else get_viewport().get_mouse_position()
	var radius := (4.0 if precise else 18.0) + recoil * 18.0
	var color := Color("fff5b7") if precise else Color(1, 1, 1, 0.8)
	draw_arc(center, radius, 0, TAU, 40, Color(0.08, 0.12, 0.08, 0.8), 4, true)
	draw_arc(center, radius, 0, TAU, 40, color, 1.5, true)
	draw_circle(center, 1.5, color)
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		draw_line(center + direction * (radius + 3), center + direction * (radius + 8), color, 2, true)
