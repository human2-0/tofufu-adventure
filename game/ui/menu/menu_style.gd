class_name MenuStyle
extends RefCounted

const INK := Color("193a37")
const MUTED := Color("55716b")
const CREAM := Color("fff9e9")
const MINT := Color("c9efbb")
const SOY_GOLD := Color("f4c75d")
const LEAF := Color("73b88d")
const BERRY := Color("f08083")
const NIGHT := Color("173632")

static func panel(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(20)
	style.border_color = Color("80ae91")
	style.set_border_width_all(2)
	style.shadow_color = Color(0.08, 0.18, 0.16, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

static func button_box(state: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(11)
	style.set_content_margin_all(12)
	style.border_color = INK
	style.set_border_width_all(2)
	style.shadow_color = Color(0.10, 0.22, 0.20, 0.24)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 3)
	match state:
		"hover":
			style.bg_color = Color("e7f5c8")
			style.border_color = LEAF
			style.set_border_width_all(3)
			style.shadow_color = Color("bbdf70aa")
			style.shadow_size = 8
		"focus":
			style.bg_color = Color("fff3bd")
			style.border_color = SOY_GOLD
			style.set_border_width_all(4)
			style.shadow_color = Color("f4c75d88")
			style.shadow_size = 10
		"pressed":
			style.bg_color = Color("bde6a7")
			style.shadow_size = 1
			style.shadow_offset = Vector2(0, 1)
		"disabled":
			style.bg_color = Color("e0e7d8")
			style.border_color = Color("9daf9d")
			style.shadow_size = 0
		_:
			style.bg_color = CREAM
	return style

static func make_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	for type in ["Label", "Button", "CheckButton", "OptionButton", "LineEdit", "TabContainer"]:
		result.set_color("font_color", type, INK)
	result.set_color("font_hover_color", "Button", INK)
	result.set_color("font_pressed_color", "Button", INK)
	result.set_color("font_focus_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("8c9c8e"))
	for type in ["Button", "OptionButton", "LineEdit"]:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			result.set_stylebox(state, type, button_box(state))
	for type in ["CheckButton", "HSlider"]:
		result.set_color("font_hover_color", type, LEAF)
		result.set_color("font_focus_color", type, SOY_GOLD)
	result.set_stylebox("panel", "PanelContainer", panel(CREAM))
	result.set_stylebox("panel", "TabContainer", panel(CREAM, 12))
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
	var item := MangaButton.new()
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
