class_name CharacterSheetTraining
extends RefCounted
## A compact skill grid and care row fit together on a full-size character sheet.

static func build(sheet: CharacterSheet, parent: Control) -> void:
	var body := CharacterSheetStyle.scroll(parent)
	body.add_theme_constant_override("separation", 6)
	var heading := HBoxContainer.new()
	body.add_child(heading)
	var title := CharacterSheetStyle.label(heading, "PRACTICE & POTENTIAL", 15, CharacterSheetStyle.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	sheet.points = CharacterSheetStyle.label(heading, "", 16, CharacterSheetStyle.PAPER)
	sheet.points.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.points.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	CharacterSheetStyle.label(body, "One point per level. Choose a permanent improvement below. Weapon skills also grow through practice.", 14)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	body.add_child(grid)
	for config in CharacterStats.SKILL_CONFIG: _skill(sheet, grid, config)
	CharacterSheetStyle.label(body, "A LIFE TOGETHER", 15, CharacterSheetStyle.GOLD)
	var care := HBoxContainer.new()
	care.add_theme_constant_override("separation", 8)
	body.add_child(care)
	var descriptions := ["Walk & run on land · +3% speed per medal", "Land real hits · +4% attack speed per medal", "Food/medicine restore missing HP · +8% HP/SP recovery per medal"]
	for description in descriptions: _journey(sheet, care, description)

static func _card(parent: Control) -> VBoxContainer:
	var box := CharacterSheetStyle.card(parent)
	box.add_theme_constant_override("separation", 4)
	var card := box.get_parent() as Control
	card.add_theme_stylebox_override("panel", CharacterSheetStyle.style(CharacterSheetStyle.INK, Color.TRANSPARENT, 8))
	CharacterSheetStyle.focus_card(card)
	return box

static func _skill(sheet: CharacterSheet, parent: Control, config: Array) -> void:
	var key: String = config[0]
	var box := _card(parent)
	var row := HBoxContainer.new()
	box.add_child(row)
	var title: String = config[1] if key != "magic" else "Magic (reserved)"
	var label := CharacterSheetStyle.label(row, title, 14, CharacterSheetStyle.PAPER)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button := CharacterSheetStyle.button(row, "+1")
	button.custom_minimum_size.y = 28
	for state in ["normal", "disabled"]:
		button.add_theme_stylebox_override(state, CharacterSheetStyle.style(Color("234a40"), Color.TRANSPARENT, 6))
	button.pressed.connect(sheet.stat_point_allocated.emit.bind(key))
	var benefit := CharacterSheetStyle.label(box, "", 13)
	var bar := CharacterSheetStyle.bar(box, Color(config[2]))
	var practice := CharacterSheetStyle.label(box, "", 11)
	sheet.skills[key] = {"label": label, "bar": bar, "button": button, "title": title, "benefit": benefit, "card": box.get_parent(), "practice": practice}

static func _journey(sheet: CharacterSheet, parent: Control, description: String) -> void:
	var box := _card(parent)
	var title := CharacterSheetStyle.label(box, "", 17, CharacterSheetStyle.PAPER)
	CharacterSheetStyle.label(box, description, 14)
	var bar := CharacterSheetStyle.bar(box, CharacterSheetStyle.GOLD)
	var progress := CharacterSheetStyle.label(box, "", 14, CharacterSheetStyle.MINT)
	sheet.milestones.append({"title": title, "bar": bar, "progress": progress})
