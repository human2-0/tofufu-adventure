class_name LobbyFlow
extends Node

var menu: LaunchMenu
var room: PlaytestRoom
var connection: SessionConnection
var go_back: Callable
var store: SaveStore
var save_slot: int = -1
var save_data: Dictionary = {}
var panel: LobbyPanel
var peer_transport: SessionTransport
var server_transport: OracleTransport
var preferences: GamePreferences
var _nickname_error: bool = false

func show_lobby() -> void:
	if preferences.nickname.is_empty():
		_nickname_error = preferences.remember_nickname("") != OK
	var content := menu.clear_page("Adventure together", "CO-OP  /  UP TO FOUR FRIENDS")
	menu.set_page_width(680)
	content.add_theme_constant_override("separation", 8)
	panel = LobbyPanel.new()
	panel.nickname = preferences.nickname
	panel.can_host = connection.transport.can_host()
	panel.discovery_description = connection.transport.discovery_description()
	content.add_child(panel)
	panel.discover.connect(_discover)
	panel.nickname_changed.connect(_nickname_changed)
	panel.host.connect(_host_world)
	panel.set_adventures(store.list_saves() if store != null else [])
	panel.join.connect(room.join_room)
	panel.begin.connect(room.begin)
	panel.leave.connect(room.leave)
	panel.back.connect(func() -> void:
		connection.disconnect_session()
		go_back.call())
	if not room.changed.is_connected(_refresh): room.changed.connect(_refresh)
	_add_connection_choices(content)
	if panel.can_host: connection.ensure_discovery(preferences.nickname)
	_refresh()

func _refresh() -> void:
	if is_instance_valid(panel):
		panel.update_state(room.peers, room.local_key, room.host_key, room.hosting, room.members.size(), room.status, room.pending_host())
		panel.show_connection(connection.discovering, connection.failed, not room.local_key.is_empty(), not room.pending_host().is_empty())
		if _nickname_error: panel.status.text += "\nNickname could not be saved on this device."

func _discover(display_name: String) -> void:
	connection.discover(display_name)

func _nickname_changed(value: String) -> void:
	if not room.host_key.is_empty() or not room.pending_host().is_empty(): return
	var normalized := GamePreferences.clean_nickname(value)
	if normalized.is_empty(): return
	var changed := normalized != preferences.nickname
	if not changed and not _nickname_error: return
	_nickname_error = preferences.remember_nickname(normalized) != OK
	panel.identity.nickname = preferences.nickname
	if changed and (panel.can_host or connection.discovering): connection.discover(preferences.nickname)
	_refresh()

func _host_world(slot: int) -> void:
	_host(slot)
	if room.hosting: room.begin()

func _host(slot: int) -> void:
	save_slot = slot
	save_data = {}
	if store == null: return
	if slot >= 0:
		save_data = store.read_slot(slot)
		if save_data.is_empty():
			panel.status.text = "Could not read that adventure. Select another save."
			return
	else:
		save_slot = store.free_slot()
		if save_slot < 0:
			panel.status.text = "All save slots are full. Free a slot in Continue before hosting a new adventure."
			return
		save_data = {"name": "Our world · %d" % (save_slot + 1)}
	if not _can_admit(room.local_key):
		panel.status.text = "This adventure already has 32 saved beans. Use its original profile or choose another adventure."
		return
	room.admission = _can_admit
	room.create_room()

func _can_admit(key: String) -> bool:
	var identities: Dictionary = save_data.get("coop", {}).get("party", {}).duplicate()
	for member: String in room.members: identities[member] = true
	return identities.has(key) or identities.size() < 32

func _add_connection_choices(content: VBoxContainer) -> void:
	var options := VBoxContainer.new()
	content.add_child(options)
	options.visible = connection.transport == server_transport
	var toggle := MenuStyle.button(panel.footer, "Connection options", func() -> void: options.visible = not options.visible, MenuIcons.SETTINGS)
	toggle.custom_minimum_size.y = 40
	content = options
	MenuStyle.paragraph(content, connection.transport.discovery_description())
	if peer_transport != null and server_transport != null:
		var modes := OptionButton.new()
		modes.add_item("Friends · Holepunch")
		modes.add_item("Dedicated server · Local / Oracle")
		modes.select(1 if connection.transport == server_transport else 0)
		content.add_child(modes)
		modes.item_selected.connect(func(index: int) -> void:
			modes.disabled = true
			panel.hide()
			await connection.select_transport(server_transport if index == 1 else peer_transport)
			show_lobby())
	if connection.transport == server_transport:
		MenuStyle.button(content, "Choose player connection file…", _choose_profile)
		MenuStyle.paragraph(content, "Each player needs their own connection file from the server owner. Keep it to rejoin your saved character.")

func _choose_profile() -> void:
	var picker := FileDialog.new()
	picker.access = FileDialog.ACCESS_FILESYSTEM
	picker.show_hidden_files = true
	picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	picker.filters = PackedStringArray(["*.json ; Player connection"])
	picker.title = "Choose your player connection file"
	menu.add_child(picker)
	picker.file_selected.connect(func(path: String) -> void:
		connection.disconnect_session()
		server_transport.credential_file = path
		server_transport.credentials.clear()
		panel.status.text = "Connection file selected. Choose Connect to server."
		picker.queue_free())
	picker.canceled.connect(picker.queue_free)
	picker.popup_centered_ratio(0.7)
