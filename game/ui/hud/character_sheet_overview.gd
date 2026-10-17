class_name CharacterSheetOverview
extends RefCounted
## Final values remain scannable; a persistent inspector explains the chosen stat.

static func build(sheet: CharacterSheet, parent: Control) -> void:
	var left := CharacterSheetStyle.scroll(parent)
	(left.get_parent() as Control).size_flags_stretch_ratio = 1.6
	_vitals(sheet, left)
	for group in [["VITALITY & MOVEMENT", [0, 1, 2], 3], ["COMBAT", [3, 4, 5, 6], 2], ["RECOVERY", [7, 8], 2]]:
		CharacterSheetStyle.label(left, group[0], 13, CharacterSheetStyle.GOLD)
		var grid := GridContainer.new()
		grid.columns = group[2]
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		left.add_child(grid)
		for index: int in group[1]: _stat(sheet, grid, index)
	var right := CharacterSheetStyle.scroll(parent)
	var detail := CharacterSheetStyle.card(right)
	CharacterSheetStyle.label(detail, "STAT INSPECTOR", 12, CharacterSheetStyle.GOLD)
	sheet.inspector_title = CharacterSheetStyle.label(detail, "", 20, CharacterSheetStyle.PAPER)
	sheet.inspector_value = CharacterSheetStyle.label(detail, "", 32, CharacterSheetStyle.MINT)
	sheet.inspector_description = CharacterSheetStyle.label(detail, "", 14)
	sheet.inspector_bar = CharacterStatBar.new()
	detail.add_child(sheet.inspector_bar)
	for source in ["Base", "Training", "Equipment"]:
		var row := HBoxContainer.new()
		detail.add_child(row)
		var label := CharacterSheetStyle.label(row, source, 14, {"Base": CharacterStatBar.BASE, "Training": CharacterStatBar.TRAINING, "Equipment": CharacterStatBar.EQUIPMENT}[source])
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value := CharacterSheetStyle.label(row, "", 14, CharacterSheetStyle.PAPER)
		value.autowrap_mode = TextServer.AUTOWRAP_OFF
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sheet.inspector_sources.append(value)
	CharacterSheetStyle.label(detail, "Base = level growth. Training = skills & medals. Equipment = weapon & outfit.", 13)
	CharacterSheetStyle.label(detail, "Values round up; speeds keep decimals. Bars show contributions.", 12)
	sheet.condition = CharacterSheetStyle.label(detail, "", 13, CharacterSheetStyle.MINT)
	sheet.gear = CharacterSheetStyle.label(detail, "", 13)

static func _vitals(sheet: CharacterSheet, parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	for index in 2:
		var box := CharacterSheetStyle.card(row)
		var label := CharacterSheetStyle.label(box, "", 14, CharacterSheetStyle.PAPER)
		var bar := CharacterSheetStyle.bar(box, Color("ef927f") if index == 0 else Color("86d9c0"))
		sheet.vitals.append({"label": label, "bar": bar})

static func _stat(sheet: CharacterSheet, parent: Control, index: int) -> void:
	var button := CharacterSheetStyle.button(parent, "")
	button.custom_minimum_size.y = 66
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.toggle_mode = true
	button.mouse_entered.connect(sheet.inspect_stat.bind(index))
	button.focus_entered.connect(sheet.inspect_stat.bind(index))
	button.pressed.connect(sheet.inspect_stat.bind(index))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var title := CharacterSheetStyle.label(box, "", 13, CharacterSheetStyle.PAPER)
	var value := CharacterSheetStyle.label(box, "", 18, CharacterSheetStyle.MINT)
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	var bar := CharacterStatBar.new()
	bar.custom_minimum_size.y = 4
	box.add_child(bar)
	box.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size.y = maxf(66, box.get_combined_minimum_size().y + 14))
	sheet.stat_rows.append({"title": title, "value": value, "bar": bar, "button": button})
