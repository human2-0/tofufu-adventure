class_name BattleDeploymentPanel
extends CanvasLayer
## Bounded display data and selection intents; no session or gameplay decisions.
signal chosen(plant: int, confirm: bool)
signal leave_requested
var map: BattlePlantMap
var picker: OptionButton
var confirm: Button
var status: Label
var heading: Label
var hint: Label
var _root: PanelContainer
var _values: Dictionary = {}
var _note: String = ""
var _stamp: String = ""

func _ready() -> void:
	layer = 11
	_root = PanelContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_theme_stylebox_override("panel", MenuStyle.panel(Color("10291a"), 12))
	add_child(_root)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	_root.add_child(stack)
	heading = MenuStyle.label(stack, "Choose your soybean plant", 22, MenuStyle.SOY_GOLD)
	hint = MenuStyle.paragraph(stack, "")
	map = BattlePlantMap.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(map)
	map.selected.connect(func(index: int) -> void: chosen.emit(index, false))
	var row := HBoxContainer.new()
	stack.add_child(row)
	picker = OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(picker)
	picker.item_selected.connect(func(index: int) -> void: chosen.emit(index, false))
	confirm = MenuStyle.button(row, "Emerge here", func() -> void: chosen.emit(int(_values.get("choice", -1)), true))
	MenuStyle.button(row, "Leave", leave_requested.emit)
	status = MenuStyle.paragraph(stack, "")
	status.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hide()

func display(values: Dictionary) -> void:
	_values = values
	visible = bool(values.get("visible", false))
	if not visible: return
	_translate()

func note(text: String) -> void:
	_note = text
	_translate()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_instance_valid(status):
		_stamp = ""
		_translate()

func _translate() -> void:
	if _values.is_empty(): return
	map.bounds = _values.get("bounds", Rect2(-500, -500, 1000, 1000))
	map.terrain = _values.get("terrain")
	map.sites = _values.get("sites", [])
	map.states.assign(_values.get("states", []))
	map.highlighted = int(_values.get("choice", -1))
	map.queue_redraw()
	var stamp := str(map.states) + TranslationServer.get_locale()
	if stamp != _stamp:
		_stamp = stamp
		picker.clear()
		for index in map.sites.size():
			var title := tr("Soybean plant #%d") % (index + 1)
			if map.states[index] == 1: title += " · " + tr("Taken")
			elif map.states[index] == 3: title += " · " + tr("Teammate")
			picker.add_item(title)
			picker.set_item_disabled(index, map.states[index] == 1)
	picker.select(map.highlighted)
	var locked: bool = _values.get("locked", false)
	picker.disabled = locked
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE if locked else Control.MOUSE_FILTER_STOP
	confirm.disabled = locked or map.highlighted < 0
	hint.text = tr("Pick a green plant on the map or use the list. Gold is yours; grey is taken.")
	if _values.get("duos", false): hint.text += " " + tr("Blue marks your teammate. Teammates may share a plant.")
	status.text = (tr("Plant confirmed · Waiting for the other players") if locked else tr("Choose, then confirm your plant")) + " · " + tr("Auto deployment in %ds") % int(_values.get("seconds", 0))
	if not _note.is_empty(): status.text += " · " + tr(_note)
