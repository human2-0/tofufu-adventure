class_name MenuStyle
extends RefCounted

const INK := Color("183b37")
const MUTED := Color("c1d7cc")
const CREAM := Color("fff9e9")
const MINT := Color("c9efbb")
const SOY_GOLD := Color("f4c75d")
const LEAF := Color("73b88d")
const BERRY := Color("f08083")
const NIGHT := Color("183b37")

static func panel(color: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(20)
	style.border_color = CREAM
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
		"primary":
			style.bg_color = SOY_GOLD
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
	return preload("res://assets/ui/frontend/tofufu_theme.tres")

static func label(parent: Node, text: String, size: int = 18, color: Color = CREAM) -> Label:
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

static func button(parent: Node, text: String, callback: Callable, icon: Texture2D = null) -> Button:
	var item := MangaButton.new()
	item.text = text
	item.icon = icon
	item.add_theme_color_override("icon_normal_color", INK)
	item.add_theme_color_override("icon_hover_color", INK)
	item.add_theme_color_override("icon_focus_color", INK)
	item.add_theme_color_override("icon_pressed_color", INK)
	item.add_theme_constant_override("icon_max_width", 22)
	item.add_theme_constant_override("h_separation", 10)
	item.custom_minimum_size.y = 48
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(callback)
	parent.add_child(item)
	return item

static func section(parent: Node, text: String, icon: Texture2D) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var symbol := TextureRect.new()
	symbol.texture = icon
	symbol.custom_minimum_size = Vector2(24, 24)
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.self_modulate = CREAM
	row.add_child(symbol)
	label(row, text, 20)

static func focus_later(item: Control) -> void:
	var reference: WeakRef = weakref(item)
	var focus := func() -> void:
		var target: Control = reference.get_ref()
		if target != null and target.is_inside_tree(): target.grab_focus()
	focus.call_deferred()

static func fit_button(item: Button, compact: bool) -> void:
	item.custom_minimum_size.y = 36 if compact else 48
	item.add_theme_font_size_override("font_size", 14 if compact else 16)
	item.add_theme_constant_override("icon_max_width", 18 if compact else 22)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := item.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		box.set_content_margin_all(6 if compact else 12)
		item.add_theme_stylebox_override(state, box)
