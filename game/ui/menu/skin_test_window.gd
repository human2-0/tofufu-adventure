class_name SkinTestWindow
extends CanvasLayer
## A small testing chooser; app composition supplies names, icons and selection.

signal skin_selected(id: String)
signal closed
var buttons: Dictionary = {}
var _choices: VBoxContainer
var _status: Label
var _scroll: ScrollContainer
var _column: VBoxContainer
var _instructions: Label
var _note: Label

func _ready() -> void:
	layer = 30
	hide()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.panel(Color("183b37f5")))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 440
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	MenuStyle.label(column, "CHARACTER SKIN TEST", 24, MenuStyle.SOY_GOLD)
	_column = column
	_instructions = MenuStyle.paragraph(column, "Choose a skin, then walk, jump and punch to inspect it.")
	_status = MenuStyle.label(column, "", 16)
	var scroll := ScrollContainer.new()
	_scroll = scroll
	scroll.follow_focus = true
	scroll.custom_minimum_size.y = 300
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_choices = VBoxContainer.new()
	_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices.add_theme_constant_override("separation", 6)
	scroll.add_child(_choices)
	_note = MenuStyle.paragraph(column, "Testing only · This session · Local appearance")
	MenuStyle.button(column, "Close", close)
	get_viewport().size_changed.connect(_resize)
	_resize()

func _resize() -> void:
	var size := get_viewport().get_visible_rect().size
	_column.custom_minimum_size.x = minf(440, size.x - 64)
	_scroll.custom_minimum_size.y = clampf(size.y - 300, 90, 300)
	_instructions.visible = size.y >= 560
	_note.visible = size.y >= 560

func configure(choices: Array[Dictionary]) -> void:
	for choice in choices:
		var id: String = choice.id
		var button := MenuStyle.button(_choices, choice.name, func() -> void: skin_selected.emit(id), choice.icon)
		button.add_theme_constant_override("icon_max_width", 44)
		for state in ["normal", "hover", "focus", "pressed"]:
			button.add_theme_color_override("icon_" + state + "_color", Color.WHITE)
		button.expand_icon = true
		button.custom_minimum_size.y = 56
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		buttons[id] = button

func open(selected: String) -> void:
	_status.text = tr("Current skin: %s") % tr((buttons[selected] as Button).text)
	show()
	(buttons[selected] as Button).call_deferred("grab_focus")

func close() -> void:
	if not visible: return
	hide()
	closed.emit()
