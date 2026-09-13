class_name LobbyPanel
extends VBoxContainer

signal discover(name: String)
signal host(slot: int)
signal join(key: String)
signal begin
signal leave
signal back
var discovery_description: String = ""
var status: Label
var _peers: VBoxContainer
var _host: Button
var _begin: Button
var _leave: Button
var _discover: Button
var _name: LineEdit
var _adventures: OptionButton
var _signature: String = ""

func _ready() -> void:
	MenuStyle.paragraph(self, "Host a meadow, start exploring, and let up to 3 friends join whenever they’re ready.")
	MenuStyle.label(self, "Your playtest name", 18)
	var row := HBoxContainer.new()
	add_child(row)
	_name = LineEdit.new()
	_name.max_length = 24
	_name.text = "Fufu %04d" % randi_range(0, 9999)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_name)
	_discover = MenuStyle.button(row, "Discover testers", func() -> void:
		var name := _name.text.strip_edges()
		discover.emit(name if not name.is_empty() else "Fufu"))
	status = MenuStyle.paragraph(self, "")
	MenuStyle.label(self, "Adventure to host", 18)
	_adventures = OptionButton.new()
	_adventures.add_item("New shared adventure", 100)
	add_child(_adventures)
	MenuStyle.paragraph(self, "Choose a new or saved adventure. The host saves everyone’s progress.")
	var actions := HBoxContainer.new()
	add_child(actions)
	_host = MenuStyle.button(actions, "Open a meadow", func() -> void: host.emit(-1 if _adventures.get_selected_id() == 100 else _adventures.get_selected_id()))
	_begin = MenuStyle.button(actions, "Start exploring →", begin.emit)
	_leave = MenuStyle.button(actions, "Leave meadow", leave.emit)
	MenuStyle.label(self, "Other beans online", 22)
	_peers = VBoxContainer.new()
	add_child(_peers)
	MenuStyle.paragraph(self, discovery_description)
	MenuStyle.button(self, "Back to title", back.emit)
	MenuStyle.focus_later(_name)

func update_state(peers: Dictionary, local_key: String, host_key: String, hosting: bool, count: int, message: String, pending: String = "") -> void:
	status.text = message
	_adventures.disabled = not host_key.is_empty()
	_host.disabled = local_key.is_empty() or not host_key.is_empty() or not pending.is_empty()
	_begin.visible = hosting
	_begin.disabled = count < 1
	_leave.visible = not host_key.is_empty() or not pending.is_empty()
	_leave.text = "Cancel joining" if not pending.is_empty() else "Leave meadow"
	_discover.disabled = not local_key.is_empty()
	_name.editable = local_key.is_empty()
	var signature := JSON.stringify(peers) + host_key + pending
	if signature == _signature: return
	_signature = signature
	for child in _peers.get_children():
		_peers.remove_child(child)
		child.queue_free()
	if peers.is_empty():
		MenuStyle.paragraph(_peers, "No other beans found yet. Ask another tester to open Co-op mode and choose Discover testers.")
	for key: String in peers:
		var peer: Dictionary = peers[key]
		var row := HBoxContainer.new()
		_peers.add_child(row)
		var label := MenuStyle.label(row, "%s · %s\n%s" % [peer.name, "Exploring" if peer.busy else ("Meadow open" if peer.hosting else "In lobby"), key.left(12)], 16)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button := MenuStyle.button(row, "Connecting…" if key == pending else "Join meadow", func() -> void: join.emit(key))
		button.disabled = not peer.hosting or not host_key.is_empty() or not pending.is_empty()

func set_adventures(saves: Array[Dictionary]) -> void:
	for save in saves:
		if save.valid: _adventures.add_item("Continue · " + str(save.data.name), int(save.slot))

func select_adventure(slot: int) -> void:
	for index in _adventures.item_count:
		if _adventures.get_item_id(index) == slot: _adventures.select(index)
