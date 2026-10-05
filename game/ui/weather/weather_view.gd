class_name WeatherView
extends CanvasLayer
## Persistent forecast; receives presentation values only.

var _label: Label

func _ready() -> void:
	layer = 0
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.position = Vector2(-245, 28)
	_label.size = Vector2(490, 45)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("e2f0ec"))
	_label.add_theme_color_override("font_shadow_color", Color("233a49"))
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func present(title: String, raining: bool, windy: bool = false) -> void:
	_label.text = title + (" · Snails thriving!\n5 per camp · stronger · faster respawns" if raining else " · Gusts slow you when walking into them" if windy else " · Cloud cover" if title == "OVERCAST" else " · Calm fields")

func present_winter(snowing: bool, windy: bool, flurries: bool) -> void:
	var title := "SNOWFALL" if snowing else ("BLOWING SNOW" if windy else ("SNOW FLURRIES" if flurries else "WINTER CLEAR"))
	_label.text = title + " · Snow slows your footing · Ice takes longer to stop"
