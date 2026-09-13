class_name MenuStyle
extends RefCounted

const INK := Color("294b46")
const MUTED := Color("688079")
const CREAM := Color("fff9e9")
const MINT := Color("cae6bb")

static func panel(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(18)
	style.border_color = Color("91b6a2")
	style.set_border_width_all(1)
	return style

static func make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	for type in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit"]:
		result.set_color("font_color", type, INK)
	result.set_color("font_hover_color", "Button", INK)
	result.set_color("font_pressed_color", "Button", INK)
	result.set_color("font_focus_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("8c9c8e"))
	for type in ["Button", "OptionButton", "LineEdit"]:
		result.set_stylebox("normal", type, panel(CREAM, 12))
		result.set_stylebox("hover", type, panel(Color("e7efce"), 12))
		result.set_stylebox("pressed", type, panel(MINT, 12))
		result.set_stylebox("disabled", type, panel(Color("e2e5d7"), 12))
		var focus := panel(Color.TRANSPARENT, 12)
		focus.border_color = Color("dc9766")
		focus.set_border_width_all(3)
		result.set_stylebox("focus", type, focus)
	result.set_stylebox("panel", "PanelContainer", panel(CREAM))
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 12)
	return result

static func label(parent: Node, text: String, size: int = 18, color: Color = INK) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", color)
	parent.add_child(item)
	return item

static func paragraph(parent: Node, text: String) -> Label:
	var item := label(parent, text, 16, MUTED)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item

static func button(parent: Node, text: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = 48
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

static func focus_later(item: Control) -> void:
	var reference: WeakRef = weakref(item)
	var focus := func() -> void:
		var target: Control = reference.get_ref()
		if target != null and target.is_inside_tree(): target.grab_focus()
	focus.call_deferred()
