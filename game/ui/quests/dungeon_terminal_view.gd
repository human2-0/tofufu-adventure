class_name DungeonTerminalView
extends CanvasLayer
## Close terminal presentation. App owns range, camera, password and state.

signal password_submitted(raw_text: String)
signal closed

const HINT := "The last operator dropped the shift note below the service return."
const MAX_INPUT := 32
var _root: Control
var _field: LineEdit
var _message: Label
var _silhouette: DungeonIngredientSilhouette
var _formula: Label
var _submit: Button
var _keyboard: DungeonVirtualKeyboard
var _prior_focus: WeakRef
var _active := false

func _ready() -> void:
	layer = 20
	visible = false
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color("071715b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(530, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	MenuStyle.label(column, "FACTORY BATCH TERMINAL", 21)
	MenuStyle.paragraph(column, "Enter operator access to inspect this batch specification.")
	_field = LineEdit.new()
	_field.placeholder_text = "Operator access"
	_field.max_length = MAX_INPUT
	_field.secret = true
	_field.text_submitted.connect(func(_text: String) -> void: _submit_password())
	column.add_child(_field)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_submit = MenuStyle.button(actions, "Submit", _submit_password)
	MenuStyle.button(actions, "? Hint", _show_hint)
	MenuStyle.button(actions, "Back", close)
	_message = MenuStyle.paragraph(column, "")
	_silhouette = DungeonIngredientSilhouette.new()
	column.add_child(_silhouette)
	_silhouette.visible = false
	_formula = MenuStyle.paragraph(column, "")
	_keyboard = DungeonVirtualKeyboard.new()
	_keyboard.character_entered.connect(_append_character)
	_keyboard.delete_pressed.connect(_delete_character)
	_keyboard.submit_pressed.connect(_submit_password)
	_keyboard.cancel_pressed.connect(_hide_keyboard)
	column.add_child(_keyboard)
	MenuStyle.button(column, "Controller keyboard", _show_keyboard)

func open() -> void:
	if _active:
		return
	var focused := get_viewport().gui_get_focus_owner()
	_prior_focus = weakref(focused) if focused != null else null
	_active = true
	visible = true
	_field.text = ""
	_message.text = ""
	_formula.text = ""
	_silhouette.visible = false
	_submit.disabled = false
	_keyboard.hide_keyboard()
	MenuStyle.focus_later(_field)

func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	_keyboard.hide_keyboard()
	_restore_focus()
	closed.emit()

func set_submission_available(available: bool) -> void:
	_submit.disabled = not available

func show_feedback(message: String) -> void:
	_message.text = message
	_submit.disabled = false

func show_formula(formula_text: String) -> void:
	_formula.text = formula_text
	_silhouette.visible = true
	_submit.disabled = true

func _submit_password() -> void:
	if not _active or _submit.disabled:
		return
	_submit.disabled = true
	password_submitted.emit(_field.text)

func _show_hint() -> void:
	_message.text = HINT

func _show_keyboard() -> void:
	_keyboard.show_and_focus()

func _hide_keyboard() -> void:
	_keyboard.hide_keyboard()
	MenuStyle.focus_later(_field)

func _append_character(character: String) -> void:
	if _field.text.length() < MAX_INPUT:
		_field.text += character

func _delete_character() -> void:
	if not _field.text.is_empty():
		_field.text = _field.text.substr(0, _field.text.length() - 1)

func _restore_focus() -> void:
	if _prior_focus == null:
		return
	var previous: Control = _prior_focus.get_ref()
	if previous != null and previous.is_inside_tree() and previous.is_visible_in_tree():
		MenuStyle.focus_later(previous)
	_prior_focus = null

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("ui_cancel"):
		if _keyboard.visible:
			_hide_keyboard()
		else:
			close()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.is_pressed() and not _keyboard.visible:
		_show_keyboard()
		get_viewport().set_input_as_handled()
