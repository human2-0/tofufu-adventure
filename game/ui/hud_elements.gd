class_name HUDElements
extends RefCounted
## Shared styling helpers for lightweight, frosted kawaii HUD containers.

static func make_panel(parent: Control, at: Vector2, dimensions: Vector2, anchor: Vector2 = Vector2.ZERO) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.anchor_left = anchor.x
	panel.anchor_right = anchor.x
	panel.anchor_top = anchor.y
	panel.anchor_bottom = anchor.y
	panel.offset_left = at.x
	panel.offset_top = at.y
	panel.offset_right = at.x + dimensions.x
	panel.offset_bottom = at.y + dimensions.y
	var style := StyleBoxFlat.new()
	style.bg_color = Color("143530c9")
	style.set_corner_radius_all(14)
	style.set_content_margin_all(9)
	style.border_color = Color("91d59688")
	style.set_border_width_all(2)
	style.shadow_color = Color("07171588")
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	return box

static func make_label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

static func make_bar(parent: Control, color: Color, width: float = 160, height: float = 6) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	fill.border_color = Color("fff6d5aa")
	fill.set_border_width_all(1)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("0b211ecc")
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	parent.add_child(bar)
	return bar
