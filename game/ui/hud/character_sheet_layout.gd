class_name CharacterSheetLayout
extends RefCounted
## Responsive scrollable character panel, with controller-focusable actions.

static func build(sheet: CharacterSheet) -> void:
	var panel := _panel(sheet)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	panel.add_child(body)
	_header(sheet, body)
	_columns(sheet, body)
	_label(body, "B / I / Select · Character hub    Esc / B / ○ · Close    D-pad · Focus    A / ✕ · Choose", 12)

static func _panel(sheet: CharacterSheet) -> PanelContainer:
	var shade := ColorRect.new()
	shade.color = Color("0c211fb8")
	sheet.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	sheet.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.07
	panel.anchor_bottom = 0.93
	var style := StyleBoxFlat.new()
	style.bg_color = Color("183b37fa")
	style.border_color = Color("86d9c0")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", style)
	return panel

static func _columns(sheet: CharacterSheet, body: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	body.add_child(scroll)
	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 24)
	scroll.add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.15
	left.add_theme_constant_override("separation", 7)
	columns.add_child(left)
	_attributes(sheet, left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 7)
	columns.add_child(right)
	_journey(sheet, right)
	_skills(sheet, right)
	_label(right, "EQUIPMENT", 16, Color("b6a0ef"))
	sheet.gear = _label(right, "", 12)

static func _attributes(sheet: CharacterSheet, left: VBoxContainer) -> void:
	_label(left, "YOUR ATTRIBUTES", 16, Color("f4c75d"))
	_label(left, "Mint · Base    Gold · Training\nLavender · Equipment    Coral · Gear penalty", 12)
	for index in 9: _stat(sheet, left)
	sheet.condition = _label(left, "", 12)
	_label(left, "HP recovery begins after 30 seconds without combat.\nBars show contributions; each row has its own scale.", 11)

static func _header(sheet: CharacterSheet, parent: Control) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	sheet.portrait = TextureRect.new()
	sheet.portrait.custom_minimum_size = Vector2(64, 64)
	sheet.portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(sheet.portrait)
	sheet.heading = _label(row, "MY TOFUFU", 23, Color("fff3d4"))
	sheet.heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.bag_button = Button.new()
	sheet.bag_button.text = "Equipment & Bag →"
	sheet.bag_button.pressed.connect(sheet.bag_requested.emit)
	row.add_child(sheet.bag_button)
	var close := Button.new()
	close.text = "✕"
	close.pressed.connect(sheet.close_requested.emit)
	row.add_child(close)
	sheet.experience = _bar(parent, Color("f4c75d"))

static func _stat(sheet: CharacterSheet, parent: Control) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	parent.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title := _label(row, "", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	var value := _label(row, "", 14, Color("fff3d4"))
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var bar := CharacterStatBar.new()
	box.add_child(bar)
	var detail := _label(box, "", 11, Color("b6cbc2"))
	sheet.stat_rows.append({"title": title, "value": value, "bar": bar, "detail": detail})

static func _journey(sheet: CharacterSheet, parent: Control) -> void:
	_label(parent, "A LIFE TOGETHER", 16, Color("f4c75d"))
	var descriptions := ["Walk & run on land · +1% speed per medal", "Land real hits · +1% attack speed per medal", "Restore missing HP with food/medicine\n+2% natural HP/SP recovery per medal"]
	for description in descriptions:
		var title := _label(parent, "", 14, Color("fff3d4"))
		_label(parent, description, 11)
		var bar := _bar(parent, Color("f4c75d"))
		var progress := _label(parent, "", 11)
		sheet.milestones.append({"title": title, "bar": bar, "progress": progress})

static func _skills(sheet: CharacterSheet, parent: Control) -> void:
	_label(parent, "PRACTICE & POTENTIAL", 16, Color("86d9c0"))
	sheet.points = _label(parent, "", 12, Color("f4c75d"))
	for config in CharacterStats.SKILL_CONFIG:
		var key: String = config[0]
		var row := HBoxContainer.new()
		parent.add_child(row)
		var title: String = config[1]
		if key == "magic": title = "Magic (reserved)"
		var label := _label(row, title, 12)
		label.custom_minimum_size.x = 115
		var bar := _bar(row, Color(config[2]))
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var button := Button.new()
		button.text = "+"
		button.tooltip_text = "Invest one permanent stat point"
		button.pressed.connect(sheet.stat_point_allocated.emit.bind(key))
		row.add_child(button)
		sheet.skills[key] = {"label": label, "bar": bar, "button": button, "title": title}
	_label(parent, "One point per level. Practice also raises weapon skills.\nMagic is reserved for future mana abilities.", 11)

static func _label(parent: Control, text: String, font_size: int, color: Color = Color("dce5db")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

static func _bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(60, 7)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("122d2b")
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
	parent.add_child(bar)
	return bar
