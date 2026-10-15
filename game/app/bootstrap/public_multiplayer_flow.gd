class_name PublicMultiplayerFlow
extends Node
## Composes public character setup with the dedicated authority transport.

var menu: LaunchMenu
var room: PlaytestRoom
var connection: SessionConnection
var transport: OracleTransport
var go_back: Callable
var profile := PublicProfile.new()
var panel: PublicMultiplayerPanel
var active: bool = false
var _joining: bool = false
var _confirmed: bool = false

func _ready() -> void:
	room.changed.connect(_refresh)
	menu.public_multiplayer.connect(show_public)

func show_public() -> void:
	active = true
	_joining = false
	_confirmed = false
	await connection.select_transport(transport)
	connection.disconnect_session()
	transport.public_mode = true
	var content := menu.clear_page("Public Multiplayer", "ORACLE PLAYTEST  /  UP TO FOUR PLAYERS")
	menu.set_page_width(680)
	var loaded := profile.load_profile()
	panel = PublicMultiplayerPanel.new()
	content.add_child(panel)
	panel.configure(str(profile.data.get("name", "")), profile.data.get("registered", false))
	panel.connect_requested.connect(_connect)
	panel.back_requested.connect(_back)
	if not loaded:
		panel.show_status(profile.error)
		panel.connect_button.disabled = true

func _connect(character_name: String) -> void:
	if not profile.prepare(character_name):
		panel.show_status(profile.error)
		return
	transport.credentials = {"endpoint": PublicProfile.ENDPOINT, "token": profile.data.token}
	if OS.has_environment("TOFUFU_PUBLIC_ENDPOINT"):
		transport.credentials.endpoint = OS.get_environment("TOFUFU_PUBLIC_ENDPOINT")
	_joining = false
	_confirmed = false
	panel.show_status("Connecting and saving your character…", true)
	connection.discover(character_name)

func _refresh() -> void:
	if not active or not is_instance_valid(panel) or connection._stopping: return
	if connection.failed:
		_joining = false
		panel.show_status(room.status)
	elif not room.local_key.is_empty() and not _joining:
		if not _confirmed and not profile.confirm():
			connection.disconnect_session()
			panel.show_status(profile.error)
			return
		_confirmed = true
		panel.name_field.editable = false
		panel.connect_button.text = "Enter public world"
		for key: String in room.peers:
			if room.peers[key].get("hosting", false):
				_joining = true
				panel.show_status("Joining the shared world…", true)
				room.join_room(key)
				return
	elif _joining and room.pending_host().is_empty() and not room.playing:
		panel.show_status(room.status)
		_joining = false

func show_ended(reason: String) -> void:
	await show_public()
	panel.show_status(reason + " Reconnect to continue your character.")

func _back() -> void:
	active = false
	transport.public_mode = false
	connection.disconnect_session()
	go_back.call()
