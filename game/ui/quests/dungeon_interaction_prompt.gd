class_name DungeonInteractionPrompt
extends CanvasLayer
## Small nearby focus caption; contains no objective destination or puzzle answer.

var _label: Label

func _ready() -> void:
	layer = 9
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_label.position = Vector2(-260, -90)
	_label.size = Vector2(520, 32)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_outline_color", Color("17362b"))
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

func present(text: String) -> void:
	_label.text = text
	visible = not text.is_empty()
