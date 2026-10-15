class_name CharacterStatBar
extends Control
## Segments describe contributions on a row-specific scale, never an EXP bar.

const BASE := Color("86d9c0")
const TRAINING := Color("f4c75d")
const EQUIPMENT := Color("b6a0ef")
const PENALTY := Color("ef927f")
var values: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(0, 9)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func present(data: Dictionary) -> void:
	values = data
	queue_redraw()

func _draw() -> void:
	if values.is_empty(): return
	draw_style_box(_style(Color("122d2b")), Rect2(Vector2.ZERO, size))
	var base: float = values.base
	var training: float = values.training
	var gear: float = values.gear
	var scale := maxf(1.0, maxf(base * 1.5, (base + training + maxf(0, gear)) * 1.15))
	var offset := 0.0
	for segment in [[base, BASE], [training, TRAINING], [maxf(0, gear), EQUIPMENT]]:
		var width: float = float(segment[0]) / scale * size.x
		draw_rect(Rect2(offset, 0, width, size.y), segment[1])
		offset += width
	if gear < 0:
		var width := -gear / scale * size.x
		draw_rect(Rect2(maxf(0, offset - width), 0, width, size.y), PENALTY)

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style
