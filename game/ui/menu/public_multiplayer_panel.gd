class_name PublicMultiplayerPanel
extends VBoxContainer
## Name-only character setup and explicit reconnect intents.

signal connect_requested(character_name: String)
signal back_requested
var name_field: LineEdit
var connect_button: Button
var status: Label

func configure(character_name: String, returning: bool) -> void:
	MenuStyle.paragraph(self, "A shared development world. Your character and progress stay on the server.")
	MenuStyle.label(self, "Character name", 16)
	name_field = LineEdit.new()
	name_field.placeholder_text = "e.g. MisoBean"
	name_field.max_length = 20
	name_field.text = character_name
	name_field.editable = not returning
	add_child(name_field)
	MenuStyle.paragraph(self, "3–20 letters, numbers or underscores; start with a letter. Names ignore capitalization.")
	connect_button = MenuStyle.button(self, "Enter public world" if returning else "Create character & play", _connect, MenuIcons.FRIENDS)
	name_field.text_submitted.connect(func(_value: String) -> void: _connect())
	status = MenuStyle.paragraph(self, "Welcome back, " + character_name + "." if returning else "Choose a name to start.")
	MenuStyle.paragraph(self, "No password needed. This device remembers your character. Keep a backup of your game data to carry it to another device.")
	MenuStyle.button(self, "Back", back_requested.emit, MenuIcons.ARROW)
	MenuStyle.focus_later(connect_button if returning else name_field)

func show_status(message: String, connecting: bool = false) -> void:
	status.text = message
	connect_button.disabled = connecting

func _connect() -> void:
	connect_requested.emit(name_field.text.strip_edges())
