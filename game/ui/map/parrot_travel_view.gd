class_name ParrotTravelView
extends CanvasLayer
## Compact flight hint and accessible mount/landing button; emits intent only.

signal action_requested
var prompt := Label.new()
var action_button := Button.new()

func _ready() -> void:
	layer = 9
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = MenuStyle.make_theme()
	add_child(root)
	root.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -380
	prompt.offset_right = 380
	prompt.offset_top = -110
	prompt.offset_bottom = -62
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color("fff1bc"))
	prompt.add_theme_color_override("font_outline_color", Color("183e35"))
	prompt.add_theme_constant_override("outline_size", 5)
	root.add_child(action_button)
	action_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	action_button.offset_left = -85
	action_button.offset_right = 85
	action_button.offset_top = -155
	action_button.offset_bottom = -117
	action_button.pressed.connect(action_requested.emit)
	action_button.hide()
