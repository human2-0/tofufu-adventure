extends Node
## Entry composition: menus, preferences, saves and opt-in peer playtest.

var menu: LaunchMenu
var game: Node3D
var store := SaveStore.new()
var preferences := GamePreferences.new()
var saves := SaveFlow.new()
var settings := SettingsFlow.new()
@export var transport: SessionTransport
var connection := SessionConnection.new()
var room := PlaytestRoom.new()
var lobby := LobbyFlow.new()
var _slot: int = -1
var _title: String = ""
var _seconds: float = 0
var _autosave: float = 0
var _online: bool = false
var _quitting: bool = false
var _coop: CoopSession
var _menu_layer: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	preferences.load_preferences()
	store.extra_validator = CoopCheckpoint.valid
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	add_child(_menu_layer)
	menu = LaunchMenu.new()
	_menu_layer.add_child(menu)
	menu.new_game.connect(saves.show_new)
	menu.continue_game.connect(saves.show_saves)
	menu.coop.connect(lobby.show_lobby)
	menu.settings.connect(settings.show_settings)
	menu.resume_game.connect(_resume)
	menu.save_game.connect(_save)
	menu.return_title.connect(_return_title)
	menu.quit_game.connect(_quit)
	saves.store = store
	saves.menu = menu
	saves.go_back = _home
	saves.start_requested.connect(_start)
	add_child(saves)
	settings.preferences = preferences
	settings.menu = menu
	settings.go_back = _home
	add_child(settings)
	room.started.connect(_start_coop)
	room.ended.connect(_coop_ended)
	add_child(room)
	connection.room = room
	connection.transport = transport
	add_child(connection)
	lobby.store = store
	lobby.menu = menu
	lobby.room = room
	lobby.connection = connection
	lobby.go_back = _home
	add_child(lobby)

func _home() -> void:
	menu.show_home(is_instance_valid(game), not _online or (is_instance_valid(_coop) and _coop.authority))
	if _online: menu.note.text = "Co-op keeps running · The host saves shared progress · Esc / Start to return"

func _start(slot: int, data: Dictionary) -> void:
	if slot < 0 or is_instance_valid(game): return
	if data.has("coop"):
		lobby.show_lobby()
		lobby.panel.select_adventure(slot)
		lobby.panel.status.text = "Shared adventure selected. Discover your friends, then open the meadow to continue."
		return
	_slot = slot
	_title = data.name
	_seconds = float(data.get("seconds", 0))
	_online = false
	game = preload("res://game/app/main.tscn").instantiate()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	game.play_opening = not data.get("opening_complete", false)
	add_child(game)
	if data.has("version"): AdventureSnapshot.restore(game, data)
	_resume()
	_save()

func _save() -> bool:
	if not is_instance_valid(game) or (_online and not _coop.authority): return true
	var data := AdventureSnapshot.capture(game, _title, _seconds)
	if _online: data.coop = CoopCheckpoint.capture(_coop)
	var success := store.write_slot(_slot, data)
	menu.note.text = "Adventure saved · " + _title if success else store.last_error
	if success: game.hud.announce("Adventure saved / " + _title)
	else:
		menu.show()
		_input_enabled(false)
		get_tree().paused = not _online
		_home()
		menu.note.text = store.last_error
	_autosave = 0
	return success

func _resume() -> void:
	menu.hide()
	if is_instance_valid(game): _input_enabled(true)
	get_tree().paused = false
	Input.flush_buffered_events()

func _return_title() -> void:
	if not _save(): return
	if _online:
		_online = false
		connection.disconnect_session()
	_clear_game()
	_home()

func _clear_game() -> void:
	get_tree().paused = false
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	game = null
	_slot = -1
	menu.show()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	var pause: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE
	pause = pause or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START)
	if pause and is_instance_valid(game):
		if menu.visible:
			_resume()
		else:
			menu.show()
			_input_enabled(false)
			get_tree().paused = not _online
			_home()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_instance_valid(game) and not get_tree().paused and (not _online or _coop.authority):
		_seconds += delta
		_autosave += delta
		if _autosave >= 60: _save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit()

func _quit() -> void:
	if _quitting: return
	if not _save(): return
	_quitting = true
	if is_instance_valid(game): game.process_mode = Node.PROCESS_MODE_DISABLED
	await connection.shutdown()
	get_tree().quit()

func _start_coop(hosting: bool, _members: Array, _key: String) -> void:
	_online = true
	var data := lobby.save_data if hosting else {}
	_slot = lobby.save_slot if hosting else -1
	_title = str(data.get("name", "Our meadow"))
	_seconds = float(data.get("seconds", 0))
	game = preload("res://game/app/main.tscn").instantiate()
	game.play_opening = not data.get("opening_complete", false)
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game)
	if hosting and data.has("version"): AdventureSnapshot.restore(game, data)
	_coop = CoopSession.new()
	_coop.game = game
	_coop.room = room
	if hosting and data.has("coop"): _coop.checkpoint = data.coop
	game.add_child(_coop)
	_resume()
	if hosting: _save()

func _coop_ended(reason: String) -> void:
	if not _online or _quitting: return
	if _coop.authority and not _save(): return
	_online = false
	_clear_game()
	lobby.show_lobby()
	menu.note.text = reason

func _input_enabled(enabled: bool) -> void:
	game.chat.set_menu_open(not enabled)
	if _online: _coop.local_input_enabled(enabled)
	else: (game.player.command_source as LocalPlayerInput).enabled = enabled
