class_name PodQuestHUD
extends CanvasLayer
## Receives quest display values; never determines success.

var _focus: ShaderMaterial
var _title: Label
var _instruction: Label
var _feedback: Label
var _progress: Label
var _meter: Control
var _cursor: ColorRect
var _zone: ColorRect
var _panel: PanelContainer

func _ready() -> void:
	layer = 1
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	var focus := ColorRect.new()
	focus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus = ShaderMaterial.new()
	_focus.shader = preload("res://game/ui/pod_focus.gdshader")
	focus.material = _focus
	canvas.add_child(focus)
	var chapter := Label.new()
	chapter.text = "TOFUFU     /     THE FIRST LITTLE ADVENTURE"
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	chapter.offset_top = 28
	chapter.add_theme_font_size_override("font_size", 17)
	chapter.add_theme_color_override("font_color", Color("fff0c2"))
	chapter.add_theme_color_override("font_shadow_color", Color("293e50"))
	chapter.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(chapter)
	_panel = PanelContainer.new()
	canvas.add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.offset_left = -280
	_panel.offset_right = 280
	_panel.offset_top = -230
	_panel.offset_bottom = -28
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("243c39f5")
	style.border_color = Color("b5cb8f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	_panel.add_child(box)
	_progress = _label(box, 13, Color("b7c992"))
	_title = _label(box, 26, Color("fff0c2"))
	_instruction = _label(box, 17, Color("eef0df"))
	_meter = Control.new()
	_meter.custom_minimum_size.y = 22
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_meter)
	var background := ColorRect.new()
	background.color = Color("49635a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter.add_child(background)
	_zone = ColorRect.new()
	_zone.color = Color("d8bd6b")
	_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter.add_child(_zone)
	_cursor = ColorRect.new()
	_cursor.color = Color("ffffff")
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter.add_child(_cursor)
	_feedback = _label(box, 14, Color("ced9c5"))
	get_viewport().size_changed.connect(_layout)
	_layout()

func show_step(title: String, instruction: String, feedback: String, progress: String, value: float, low: float, high: float, meter_visible: bool) -> void:
	_title.text = title
	_instruction.text = instruction
	_feedback.text = feedback
	_progress.text = progress
	_meter.visible = meter_visible
	_zone.position = Vector2(_meter.size.x * low, 0)
	_zone.size = Vector2(_meter.size.x * (high - low), 22)
	_cursor.position = Vector2(clampf(value, 0, 1) * (_meter.size.x - 4), -3)
	_cursor.size = Vector2(4, 28)

func _layout() -> void:
	var width := minf(560, get_viewport().get_visible_rect().size.x - 32)
	_panel.offset_left = -width * 0.5
	_panel.offset_right = width * 0.5
	if DisplayServer.is_touchscreen_available():
		_panel.anchor_top = 0
		_panel.anchor_bottom = 0
		_panel.offset_top = 65
		_panel.offset_bottom = 265

func _label(parent: Control, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func set_reveal(value: float) -> void:
	_focus.set_shader_parameter("reveal", value)
