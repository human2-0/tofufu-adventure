extends Node
## Entry composition: menus, preferences, saves and opt-in peer playtest. Helpers use the annotated signals/state.

var menu: LaunchMenu
var game: Node3D
var store := SaveStore.new()
var coop_store := SaveStore.new()
var preferences := GamePreferences.new()
var saves := SaveFlow.new()
var settings := SettingsFlow.new()
var updates := UpdateLogFlow.new()
@export var transport: SessionTransport
@export var server_transport: OracleTransport
var connection := SessionConnection.new()
var room := PlaytestRoom.new()
var lobby := LobbyFlow.new()
var public_play := PublicMultiplayerFlow.new()
var _slot: int = -1
var _title: String = ""
var _seconds: float = 0
var _autosave: float = 0
var _online: bool = false
@warning_ignore("unused_private_class_variable") var _quitting: bool = false
var _coop: CoopSession
var _menu_layer: CanvasLayer
var _input_flow := LaunchInput.new()
var loader := AdventureLoader.new()
var readiness := LoadingReadiness.new()

func _ready() -> void:
	GamePreferences.install_translations(get_tree())
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	preferences.load_preferences()
	RenderBudget.install(self, preferences, func() -> bool: return is_instance_valid(game) and not get_tree().paused)
	store.extra_validator = CoopCheckpoint.valid
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 20
	add_child(_menu_layer)
	menu = LaunchMenu.new()
	_menu_layer.add_child(menu)
	loader.view = LoadingView.new()
	_menu_layer.add_child(loader.view)
	loader.view.back_requested.connect(_loading_back)
	add_child(loader)
	menu.new_game.connect(saves.show_new)
	menu.continue_game.connect(saves.show_saves)
	menu.coop.connect(func() -> void:
		public_play.active = false
		lobby.show_lobby())
	menu.settings.connect(settings.show_settings)
	menu.resume_game.connect(_resume)
	menu.save_game.connect(_save)
	menu.return_title.connect(_return_title)
	menu.quit_game.connect(_quit)
	LaunchFlows.connect_flows(self)
	updates.menu = menu
	updates.go_back = _home
	updates.path = preferences.path + ".updates.cfg"
	updates.load_seen()
	menu.updates.connect(updates.show_history)
	if "--dedicated-lobby" not in OS.get_cmdline_user_args(): updates.show_unseen()
	if "--dedicated-lobby" in OS.get_cmdline_user_args() and not transport.can_host(): lobby.show_lobby()

func _home() -> void:
	menu.show_home(is_instance_valid(game), not _online or (is_instance_valid(_coop) and _coop.authority))
	if _online: menu.note.text = "Co-op keeps running · The host saves shared progress · Esc / Start to return"

func _start(slot: int, data: Dictionary) -> void:
	if slot < 0 or is_instance_valid(game) or loader.busy or loader.view.visible: return
	if not DungeonSnapshotValidation.adventure(data):
		menu.note.text = "The saved factory checkpoint is malformed."
		return
	if data.has("coop"):
		menu.note.text = "Continue this adventure from Co-op adventures."
		return
	_slot = slot
	_title = data.name
	_seconds = float(data.get("seconds", 0))
	_online = false
	menu.hide()
	var loaded := await loader.open(self, preferences, data, false)
	if loaded == null: return
	game = loaded
	loader.finish()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	_resume()
	_save()

func _save() -> bool:
	if not is_instance_valid(game) or (_online and (not is_instance_valid(_coop) or not _coop.authority)): return true
	var data := AdventureSnapshot.capture(game, _title, _seconds)
	if _online: data.coop = CoopCheckpoint.capture(_coop)
	var target := coop_store if _online else store
	var success := target.write_slot(_slot, data)
	menu.note.text = "Adventure saved · " + _title if success else target.last_error
	if success: game.hud.announce("Adventure saved / " + _title)
	else:
		menu.show()
		_input_enabled(false)
		get_tree().paused = not _online
		_home()
		menu.note.text = target.last_error
	_autosave = 0
	return success

func _resume() -> void:
	if loader.busy or loader.view.visible: return
	menu.hide()
	if is_instance_valid(game): _input_enabled(true)
	get_tree().paused = false
	Input.flush_buffered_events()

func _return_title() -> void:
	LaunchExit.return_title(self)

func _clear_game() -> void:
	loader.cancel()
	get_tree().paused = false
	if is_instance_valid(game):
		remove_child(game)
		game.queue_free()
	game = null
	_coop = null
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
	if is_instance_valid(game) and not loader.busy and not get_tree().paused and (not _online or _coop.authority):
		_seconds += delta
		_autosave += delta
		if _autosave >= 60: _save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit()

func _quit() -> void:
	await LaunchExit.quit(self)

func _start_coop(hosting: bool, _members: Array, _key: String) -> void:
	if loader.busy or loader.view.visible or is_instance_valid(game): return
	_online = true
	var data := lobby.save_data if hosting else {}
	_slot = lobby.save_slot if hosting else -1
	_title = str(data.get("name", tr("Our world")))
	_seconds = float(data.get("seconds", 0))
	menu.hide()
	var loaded := await loader.open(self, preferences, data, true)
	if loaded == null:
		if loader.view.visible:
			_online = false
			connection.disconnect_session()
		return
	game = loaded
	_coop = CoopSession.new()
	_coop.game = game
	_coop.room = room
	_coop.public_mode = public_play.active
	if hosting and data.has("coop"): _coop.checkpoint = data.coop
	game.add_child(_coop)
	readiness.replay(_coop)
	loader.finish()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	_resume()
	if hosting: _save()

func _coop_ended(reason: String) -> void:
	LaunchFlows.coop_ended(self, reason)

func _input_enabled(enabled: bool) -> void:
	_input_flow.set_enabled(game, preferences, _online, _coop, enabled)

func _loading_back() -> void:
	if _online:
		_online = false
		connection.disconnect_session()
	loader.cancel()
	_slot = -1
	menu.show()
	_home()
