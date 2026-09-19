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

func show_lobby() -> void:
	var content := menu.clear_page("Better with a few beans", "CO-OP  /  PUBLIC PLAYTEST" if connection.transport.can_host() else "CO-OP  /  ORACLE MEADOW")
	panel = LobbyPanel.new()
	panel.can_host = connection.transport.can_host()
	panel.discovery_description = connection.transport.discovery_description()
	content.add_child(panel)
	panel.discover.connect(connection.discover)
	panel.host.connect(_host)
	panel.set_adventures(store.list_saves() if store != null else [])
	panel.join.connect(room.join_room)
	panel.begin.connect(room.begin)
	panel.leave.connect(room.leave)
	panel.back.connect(func() -> void:
		connection.disconnect_session()
		go_back.call())
	if not room.changed.is_connected(_refresh): room.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if is_instance_valid(panel):
		panel.update_state(room.peers, room.local_key, room.host_key, room.hosting, room.members.size(), room.status, room.pending_host())

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
		save_data = {"name": "Our meadow · %d" % (save_slot + 1)}
	if not _can_admit(room.local_key):
		panel.status.text = "This adventure already has 32 saved beans. Use its original profile or choose another adventure."
		return
	room.admission = _can_admit
	room.create_room()

func _can_admit(key: String) -> bool:
	var identities: Dictionary = save_data.get("coop", {}).get("party", {}).duplicate()
	for member: String in room.members: identities[member] = true
	return identities.has(key) or identities.size() < 32
