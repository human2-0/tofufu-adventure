class_name CharacterSheetStyle
extends RefCounted
## Shared visual language for the character sheet's cards and controls.

const INK := Color("102925")
const MUTED := Color("b6cec5")
const PAPER := Color("fff2d5")
const GOLD := Color("f4c75d")
const MINT := Color("86d9c0")

static func label(parent: Control, text: String, font_size: int = 14, color: Color = MUTED) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func style(color: Color, edge: Color = Color.TRANSPARENT, margin: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(margin)
	return box

static func card(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", style(INK))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box

static func button(parent: Control, text: String) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 36
	node.add_theme_font_size_override("font_size", 14)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, PAPER)
	node.add_theme_color_override("font_disabled_color", MUTED)
	node.add_theme_stylebox_override("normal", style(Color("234a40")))
	node.add_theme_stylebox_override("hover", style(Color("345e4d"), MINT))
	node.add_theme_stylebox_override("pressed", style(Color("406347"), GOLD))
	node.add_theme_stylebox_override("focus", style(Color.TRANSPARENT, GOLD))
	parent.add_child(node)
	return node

static func bar(parent: Control, color: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(30, 6)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("fill", style(color, Color.TRANSPARENT, 0))
	node.add_theme_stylebox_override("background", style(Color("29443b"), Color.TRANSPARENT, 0))
	parent.add_child(node)
	return node

static func scroll(parent: Control) -> VBoxContainer:
	var scroller := ScrollContainer.new()
	scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.follow_focus = true
	parent.add_child(scroller)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroller.add_child(box)
	return box

static func focus_card(panel: Control) -> void:
	panel.focus_mode = Control.FOCUS_ALL
	var normal := panel.get_theme_stylebox("panel")
	var focused := normal.duplicate() as StyleBoxFlat
	focused.border_color = GOLD
	panel.focus_entered.connect(panel.add_theme_stylebox_override.bind("panel", focused))
	panel.focus_exited.connect(panel.add_theme_stylebox_override.bind("panel", normal))
