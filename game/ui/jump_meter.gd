class_name JumpMeter
extends Control
## Contextual jump charge bar: appears gradually only after holding for 200ms.

var jump_bar: ProgressBar
var jump_text: Label
var _hold_time: float = 0.0
var _charging: bool = false
var _alpha: float = 0.0

func _init() -> void:
	custom_minimum_size = Vector2(170, 24)
	mouse_filter = MOUSE_FILTER_IGNORE
	modulate.a = 0.0

func _ready() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.14, 0.18, 0.55)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(4)
	style.border_color = Color("91cbb944")
	style.set_border_width_all(1)
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)

	var box := VBoxContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	bg.add_child(box)

	jump_text = Label.new()
	jump_text.mouse_filter = MOUSE_FILTER_IGNORE
	jump_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	jump_text.add_theme_font_size_override("font_size", 10)
	jump_text.add_theme_color_override("font_color", Color("dbe8c1"))
	jump_text.text = "HOLD JUMP"
	box.add_child(jump_text)

	jump_bar = ProgressBar.new()
	jump_bar.custom_minimum_size = Vector2(150, 5)
	jump_bar.show_percentage = false
	jump_bar.mouse_filter = MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("badc7d")
	fill.set_corner_radius_all(3)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.18, 0.25, 0.27, 0.7)
	background.set_corner_radius_all(3)
	jump_bar.add_theme_stylebox_override("fill", fill)
	jump_bar.add_theme_stylebox_override("background", background)
	box.add_child(jump_bar)

func update_charge(value: float, delta: float) -> void:
	if value > 0.01:
		_hold_time += delta
		_charging = true
		jump_bar.value = value * 100.0
		if value >= 1.0:
			jump_text.text = "★ SUPER JUMP READY! ★"
			jump_text.add_theme_color_override("font_color", Color("fff0a3"))
		else:
			jump_text.text = "CHARGING JUMP..."
			jump_text.add_theme_color_override("font_color", Color("dbe8c1"))
	else:
		_hold_time = 0.0
		_charging = false

	# Gradual appearance after 200ms delay
	var target_alpha := 0.0
	if _charging and _hold_time >= 0.20:
		target_alpha = 1.0

	_alpha = move_toward(_alpha, target_alpha, delta * 5.0)
	modulate.a = _alpha
	visible = _alpha > 0.005
