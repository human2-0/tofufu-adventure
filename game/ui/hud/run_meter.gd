class_name RunMeter
extends Control
## Low-reserve-only readout, with hysteresis to avoid flickering at the threshold.

var bar: ProgressBar
var caption: Label
var _low: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 11)
	caption.add_theme_color_override("font_color", Color("ffe8b1"))
	caption.add_theme_color_override("font_shadow_color", Color("243b3b"))
	caption.add_theme_constant_override("shadow_offset_y", 1)
	caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(caption)
	bar = ProgressBar.new()
	bar.position = Vector2(0, 20)
	bar.size = Vector2(190, 6)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e2bd77")
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("243b3bc9")
	background.corner_radius_top_left = 3
	background.corner_radius_top_right = 3
	background.corner_radius_bottom_left = 3
	background.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	hide()

func present(current: float, maximum: float, exhausted: bool) -> void:
	var ratio := clampf(current / maxf(1.0, maximum), 0.0, 1.0)
	if ratio <= 0.30 or exhausted: _low = true
	elif ratio >= 0.45: _low = false
	visible = _low
	bar.value = ratio * 100.0
	caption.text = "CATCH BREATH · RELEASE RUN" if exhausted else "RUN STAMINA · %d%%" % roundi(ratio * 100.0)
