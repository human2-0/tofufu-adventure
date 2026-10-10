class_name LobbyIdentity
extends VBoxContainer
## Optional nickname editing; the app owns persistence and connection changes.

signal submitted(value: String)
var nickname: String = "Fufu"
var _summary: HBoxContainer
var _editor: VBoxContainer
var _label: Label
var _edit: Button
var _input: LineEdit

func _ready() -> void:
	_summary = HBoxContainer.new()
	add_child(_summary)
	_label = MenuStyle.label(_summary, "Playing as " + nickname, 18)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_edit = MenuStyle.button(_summary, "Edit", _open, MenuIcons.EDIT)
	_edit.custom_minimum_size.y = 40
	_edit.tooltip_text = "Change your saved nickname"
	_editor = VBoxContainer.new()
	add_child(_editor)
	MenuStyle.paragraph(_editor, "Your nickname is remembered on this device.")
	_input = LineEdit.new()
	_input.max_length = 24
	_input.placeholder_text = "Your nickname"
	_editor.add_child(_input)
	_input.text_submitted.connect(_submit)
	var actions := HBoxContainer.new()
	_editor.add_child(actions)
	MenuStyle.button(actions, "Save nickname", func() -> void: _submit(_input.text), MenuIcons.BOOK)
	MenuStyle.button(actions, "Cancel", _close)
	_editor.hide()

func set_locked(locked: bool) -> void:
	_edit.disabled = locked
	if locked: _close()

func _open() -> void:
	_input.text = nickname
	_summary.hide()
	_editor.show()
	_input.grab_focus()
	_input.select_all()

func _submit(value: String) -> void:
	if value.strip_edges().is_empty():
		_input.grab_focus()
		return
	submitted.emit(value)
	_label.text = "Playing as " + nickname
	_close()

func _close() -> void:
	_editor.hide()
	_summary.show()
