class_name UpdateLogCard
extends PanelContainer
## Exact English/Polish copy is readable side by side, stacked in compact windows.

signal expanded_requested
var toggle: Button
var details: BoxContainer
var _title: Label
var _polish_title: Label
var _caption: Label

func build(entry: Dictionary) -> void:
	var box := MenuStyle.panel(Color("24463e"), 9)
	box.set_content_margin_all(10)
	box.set_border_width_all(1)
	box.border_color = Color("52745d")
	box.shadow_size = 0
	add_theme_stylebox_override("panel", box)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(body)
	toggle = Button.new()
	toggle.flat = true
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		toggle.add_theme_color_override(state, MenuStyle.SOY_GOLD)
	toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	toggle.tooltip_text = tr("Show or hide update details")
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("315342") if state in ["hover", "focus"] else Color.TRANSPARENT
		style.set_content_margin_all(4)
		style.set_corner_radius_all(5)
		toggle.add_theme_stylebox_override(state, style)
	var header := HBoxContainer.new()
	body.add_child(header)
	header.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	header.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			expanded_requested.emit()
			header.accept_event())
	var headlines := VBoxContainer.new()
	headlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	headlines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(headlines)
	_caption = MenuStyle.label(headlines, "%s  ·  #%d" % [entry.date, entry.id], 11, MenuStyle.SOY_GOLD)
	_caption.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title = MenuStyle.paragraph(headlines, String(entry.title))
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.add_theme_color_override("font_color", MenuStyle.CREAM)
	_polish_title = MenuStyle.paragraph(headlines, _polish(String(entry.title)))
	_polish_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_polish_title.add_theme_font_size_override("font_size", 13)
	for label in [_title, _polish_title, _caption]: label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggle.text = "+"
	toggle.custom_minimum_size = Vector2(36, 36)
	toggle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(toggle)
	toggle.pressed.connect(expanded_requested.emit)
	details = BoxContainer.new()
	details.add_theme_constant_override("separation", 16)
	body.add_child(details)
	_bullets(entry.bullets, "English", false)
	_bullets(entry.bullets, "Polski", true)
	details.hide()

func _bullets(bullets: Array, caption: String, polish: bool) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(column)
	var language := MenuStyle.label(column, caption, 12, MenuStyle.MINT)
	language.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	for source: String in bullets:
		var row := HBoxContainer.new()
		column.add_child(row)
		var bullet := MenuStyle.label(row, "•", 14, MenuStyle.SOY_GOLD)
		bullet.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var text := MenuStyle.paragraph(row, _polish(source) if polish else source)
		text.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 14)

func set_expanded(expanded: bool) -> void:
	details.visible = expanded
	toggle.text = "−" if expanded else "+"
	toggle.set_meta("expanded", expanded)

func fit(compact: bool) -> void:
	details.vertical = compact
	_title.add_theme_font_size_override("font_size", 15 if compact else 17)

static func _polish(source: String) -> String:
	return String(preload("res://game/settings/localization/pl.po").get_message(source))
