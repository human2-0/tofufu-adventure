class_name CharacterSheetLayout
extends RefCounted
## Persistent identity and navigation frame; each page owns its content layout.

static func build(sheet: CharacterSheet) -> void:
	var shade := ColorRect.new()
	shade.color = Color("071b18df")
	sheet.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	sheet.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = 0.035
	panel.anchor_right = 0.965
	panel.anchor_top = 0.035
	panel.anchor_bottom = 0.965
	panel.add_theme_stylebox_override("panel", CharacterSheetStyle.style(Color("18392ffa"), Color("6b9380"), 16))
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	panel.add_child(body)
	_header(sheet, body)
	var navigation := HBoxContainer.new()
	body.add_child(navigation)
	for title in ["Attributes", "Training & Care"]:
		var button := CharacterSheetStyle.button(navigation, title)
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(sheet.select_page.bind(sheet.page_buttons.size()))
		sheet.page_buttons.append(button)
	var pages := Control.new()
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(pages)
	for index in 2:
		var page := HBoxContainer.new()
		pages.add_child(page)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.add_theme_constant_override("separation", 18)
		sheet.pages.append(page)
	CharacterSheetOverview.build(sheet, sheet.pages[0])
	CharacterSheetTraining.build(sheet, sheet.pages[1])
	sheet.footer = CharacterSheetStyle.label(body, "", 12)
	sheet.select_page(0)

static func _header(sheet: CharacterSheet, parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	sheet.portrait = TextureRect.new()
	sheet.portrait.custom_minimum_size = Vector2(64, 64)
	sheet.portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet.portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(sheet.portrait)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(identity)
	sheet.heading = CharacterSheetStyle.label(identity, "MY TOFUFU", 23, CharacterSheetStyle.PAPER)
	sheet.experience_label = CharacterSheetStyle.label(identity, "", 13, CharacterSheetStyle.GOLD)
	sheet.experience = CharacterSheetStyle.bar(identity, CharacterSheetStyle.GOLD)
	sheet.bag_button = CharacterSheetStyle.button(row, "Inventory →")
	sheet.bag_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sheet.bag_button.pressed.connect(sheet.bag_requested.emit)
	var close := CharacterSheetStyle.button(row, "✕")
	close.tooltip_text = "Close player info"
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(sheet.close_requested.emit)
