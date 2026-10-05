class_name DungeonVirtualKeyboard
extends VBoxContainer
## Controller-accessible text entry. The parent owns the text and submission.

signal character_entered(character: String)
signal delete_pressed
signal cancel_pressed
signal submit_pressed

const ROWS: Array[String] = ["ABCDEFGH", "IJKLMNOP", "QRSTUVWX", "YZ012345"]
var _first_key: Button

func _ready() -> void:
	visible = false
	add_theme_constant_override("separation", 5)
	for row_text: String in ROWS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		add_child(row)
		for character: String in row_text:
			var key := _key(row, character)
			key.pressed.connect(func() -> void: character_entered.emit(character))
			if _first_key == null:
				_first_key = key
	var actions := HBoxContainer.new()
	add_child(actions)
	_key(actions, "Space").pressed.connect(func() -> void: character_entered.emit(" "))
	_key(actions, "Delete").pressed.connect(func() -> void: delete_pressed.emit())
	_key(actions, "Enter").pressed.connect(func() -> void: submit_pressed.emit())
	_key(actions, "Cancel").pressed.connect(func() -> void: cancel_pressed.emit())

func _key(row: HBoxContainer, caption: String) -> Button:
	var key := Button.new()
	key.text = caption
	key.custom_minimum_size = Vector2(44, 36)
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key)
	return key

func show_and_focus() -> void:
	visible = true
	if _first_key != null:
		MenuStyle.focus_later(_first_key)

func hide_keyboard() -> void:
	visible = false
