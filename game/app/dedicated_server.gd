class_name DedicatedServer
extends Node
## Server-owned simulation and checkpoints, independent of any participating client.

@export var transport: SessionTransport
var room := PlaytestRoom.new()
var game: Node3D
var session: CoopSession
var store := SaveStore.new()
var state_directory: String = "/var/lib/tofufu"
var _clock: float = 0
var _seconds: float = 0

func _ready() -> void:
	if OS.has_environment("TOFUFU_STATE_DIR"): state_directory = OS.get_environment("TOFUFU_STATE_DIR")
	store.directory = state_directory
	store.extra_validator = CoopCheckpoint.valid
	room.dedicated = true
	room.send_packet = transport.send_packet
	transport.event_received.connect(_event)
	add_child(room)
	transport.start("Oracle meadow")

func _event(event: Dictionary) -> void:
	room.receive(event)
	if event.get("type") == "ready": _start_world()
	elif event.get("type") == "error":
		push_error(str(event.get("message")))
		get_tree().quit(1)

func _start_world() -> void:
	var data := store.read_slot(0)
	if FileAccess.file_exists(store.directory.path_join("adventure_00.json")) and (data.is_empty() or not data.has("coop")):
		push_error("Server checkpoint is invalid; refusing to overwrite it.")
		transport.close()
		get_tree().quit(1)
		return
	game = preload("res://game/app/main.tscn").instantiate()
	# A persistent public world starts after the one-time pod introduction.
	game.play_opening = false
	add_child(game)
	if not data.is_empty():
		AdventureSnapshot.restore(game, data)
		_seconds = float(data.seconds)
	room.create_room()
	room.begin()
	session = CoopSession.new()
	session.game = game
	session.room = room
	if not data.is_empty(): session.checkpoint = data.coop
	game.add_child(session)
	session.local_input_enabled(false)
	game.shooting_view.process_mode = Node.PROCESS_MODE_DISABLED
	game.chat.set_menu_open(true)
	game.chat.set_process(false)
	if not save_world():
		transport.close()
		get_tree().quit(1)
		return
	print("ORACLE_READY")

func _process(delta: float) -> void:
	if session == null: return
	_seconds += delta
	_clock += delta
	if _clock >= 30: save_world()
	var stop_file := state_directory.path_join("stop-request")
	if FileAccess.file_exists(stop_file):
		if not save_world():
			get_tree().quit(1)
			return
		DirAccess.remove_absolute(stop_file)
		room.leave("The Oracle meadow is updating. Please reconnect shortly.")
		transport.close()
		get_tree().quit()

func save_world() -> bool:
	if session == null: return false
	var data := AdventureSnapshot.capture(game, "Oracle meadow", _seconds)
	data.coop = CoopCheckpoint.capture(session)
	_clock = 0
	var success := store.write_slot(0, data)
	if not success: push_error(store.last_error)
	return success

func _exit_tree() -> void:
	transport.close()
