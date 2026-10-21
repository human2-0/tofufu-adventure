class_name BattleLobbyPanel
extends VBoxContainer
## Display-only lobby. App composition supplies roster, skins and connection state.

signal practice
signal find_match
signal host_friends
signal join_invite(code: String)
signal start_match
signal copy_invite
signal leave
signal skin_changed(index: int)
signal locale_changed

var career: Label
var armour_hint: Label
var _career_caption: String = ""
var _career_records: String = ""
var status: Label
var roster: Label
var picker: OptionButton
var start_button: Button
var copy_button: Button
var nickname: LineEdit
var invite: LineEdit
var portrait: TextureRect
var actions: VBoxContainer
var _modes: GridContainer
var cpu_options: BattleCPUOptions
var practice_button: Button
var _names := PackedStringArray()
var duos: bool = false

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	MenuStyle.paragraph(self, "Up to 50 CPUs. Survive solo or with your duo, scavenge gear, hunt adventure mobs and outrun the storm.")
	armour_hint = MenuStyle.paragraph(self, "Armour regenerates to 50 after 8 seconds without damage. Health needs food.")
	career = MenuStyle.paragraph(self, "")
	career.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var identity := HBoxContainer.new()
	add_child(identity)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(60, 60)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	identity.add_child(portrait)
	nickname = LineEdit.new()
	nickname.placeholder_text = "Your nickname"
	nickname.max_length = 24
	nickname.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(nickname)
	picker = OptionButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(picker)
	picker.item_selected.connect(skin_changed.emit)
	cpu_options = BattleCPUOptions.new()
	add_child(cpu_options)
	actions = VBoxContainer.new()
	add_child(actions)
	var modes := GridContainer.new()
	_modes = modes
	actions.add_child(modes)
	MenuStyle.button(modes, "Find a Battle Royale match", find_match.emit, MenuIcons.FRIENDS).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyle.button(modes, "Host friends · Invite code", host_friends.emit, MenuIcons.FRIENDS).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	actions.add_child(row)
	invite = LineEdit.new()
	invite.placeholder_text = "Paste a Battle Royale invite"
	invite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(invite)
	MenuStyle.button(row, "Join invite", func() -> void: join_invite.emit(invite.text))
	practice_button = MenuStyle.button(actions, "CPU practice · Play offline", practice.emit, MenuIcons.SPROUT)
	status = MenuStyle.paragraph(self, "")
	roster = MenuStyle.paragraph(self, "")
	copy_button = MenuStyle.button(self, "Copy friend invite", copy_invite.emit)
	start_button = MenuStyle.button(self, "Start match", start_match.emit)
	MenuStyle.button(self, "Back to title", leave.emit, MenuIcons.EXIT)
	MenuStyle.paragraph(self, "WASD move · Shift dash · Space jump · LMB attack · F punch · E loot · R reload · 3 heal · Tab map · Esc leave")
	MenuStyle.paragraph(self, "Direct peer play · Some networks block connections · Host recovery pauses the match")
	resized.connect(_responsive)
	_responsive()

func _responsive() -> void:
	var compact := get_viewport_rect().size.x < 900
	_modes.columns = 1 if compact else 2
	portrait.visible = not compact
	armour_hint.text = "Armour: 50 after 8s · Health: food" if compact else "Armour regenerates to 50 after 8 seconds without damage. Health needs food."
	armour_hint.add_theme_font_size_override("font_size", 13 if compact else 16)
	career.add_theme_font_size_override("font_size", 13 if compact else 16)
	career.text = _career_caption if compact else _career_caption + "\n" + _career_records
	career.tooltip_text = _career_records

func show_career(caption: String, records: String) -> void:
	_career_caption = caption
	_career_records = records
	_responsive()

func show_state(message: String, names: PackedStringArray, hosting: bool, waiting: bool, online: bool) -> void:
	status.text = message
	roster.visible = online
	_names = names
	_translate_roster()
	roster.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	start_button.visible = hosting and waiting
	copy_button.visible = hosting and online
	actions.visible = not online
	nickname.editable = not online
	picker.disabled = online

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_instance_valid(roster):
		_translate_roster()
		locale_changed.emit()

func _translate_roster() -> void:
	var lines := PackedStringArray()
	if duos:
		for index in range(0, _names.size(), 2):
			lines.append(tr("Duo %d") % (floori(index / 2.0) + 1) + ": " + " · ".join(_names.slice(index, mini(index + 2, _names.size()))))
	else: lines.append(" · ".join(_names))
	roster.text = tr("Players: %d / 20") % _names.size() + "\n" + "\n".join(lines)
