class_name CastleTrialView
extends CanvasLayer
## Receives display values; interaction intent travels through the existing input source.

var panel: PanelContainer
var title: Label
var detail: Label
var prompt: Label
var health: ProgressBar

func _ready() -> void:
	layer = 8
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.position = Vector2(-195, 10)
	panel.custom_minimum_size = Vector2(390, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.06, 0.08, 0.91)
	style.border_color = Color("c39450")
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	title = _label(column, 15, Color("ffd194"))
	health = ProgressBar.new()
	health.custom_minimum_size.y = 8
	health.show_percentage = false
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(health)
	detail = _label(column, 13, Color("f5dfd0"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt = _label(column, 14, Color("90e8de"))
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.visible = false

func _label(parent: Control, size: int, color: Color) -> Label:
	var result := Label.new()
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func present(shown: bool, heading: String, text: String, action: String, current: float, maximum: float) -> void:
	panel.visible = shown
	if not shown: return
	title.text = heading
	detail.text = text
	prompt.text = action
	prompt.visible = not action.is_empty()
	health.visible = maximum > 0
	health.max_value = maxf(1, maximum)
	health.value = current
	panel.reset_size()
