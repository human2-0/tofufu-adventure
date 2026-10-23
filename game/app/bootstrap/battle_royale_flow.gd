class_name BattleRoyaleFlow
extends Node
## Opt-in independent mode. No adventure slot, checkpoint or inventory is touched.

var app: Node
var transport: SessionTransport
var room: BattleRoom
var panel: BattleLobbyPanel
var game: BattleRoyaleGame
var channel: String = ""
var _host_pending: bool = false
var _loading: bool = false
var _generation: int = 0
var _skin: int = 0
var _options: Array = [BattleOptions.DEFAULT_CPUS, BattleOptions.NORMAL]
var loading_view: LoadingView
var _last_lobby_second: int = -1
var rounds := BattleRoundFlow.new()

func _ready() -> void:
	rounds.flow = self
	rounds.career.load_records()
	transport.event_received.connect(_receive)
	loading_view = LoadingView.new()
	app._menu_layer.add_child(loading_view)
	loading_view.back_requested.connect(leave)

func show_lobby() -> void:
	var content: VBoxContainer = app.menu.clear_page("Battle Royale", "TOFUFU ROYALE  /  50 CPUs")
	app.menu.set_page_width(760)
	panel = BattleLobbyPanel.new()
	content.add_child(panel)
	panel.locale_changed.connect(_refresh)
	panel.nickname.text = app.preferences.nickname if not app.preferences.nickname.is_empty() else "Tofufu"
	panel.picker.add_item("Fufu")
	for title: String in TofufuTestArt.NAMES: panel.picker.add_item(title)
	panel.picker.select(_skin)
	panel.skin_changed.connect(_select_skin)
	panel.cpu_options.selected.connect(_cpu_options)
	panel.cpu_options.mode_selected.connect(_team_mode)
	_select_skin(_skin)
	panel.practice.connect(_practice)
	panel.find_match.connect(func() -> void: _connect("public", true, ""))
	panel.host_friends.connect(func() -> void:
		_host_pending = true
		_connect(Crypto.new().generate_random_bytes(12).hex_encode(), false, ""))
	panel.join_invite.connect(_join_invite)
	panel.start_match.connect(func() -> void:
		if room != null: room.begin())
	panel.copy_invite.connect(_copy_invite)
	panel.leave.connect(leave)
	_refresh()

func _cpu_options(count: int, difficulty: int) -> void:
	_options = [count, difficulty, 1] if BattleOptions.duos(_options) else [count, difficulty]
	if room != null: room.configure(_options)
	_refresh()

func _team_mode(duos: bool) -> void:
	_options = [int(_options[0]), int(_options[1]), 1] if duos else _options.slice(0, 2)
	_cpu_options(int(_options[0]), int(_options[1]))

func _select_skin(index: int) -> void:
	_skin = index
	panel.portrait.texture = load("res://assets/characters/fufu/soybean_fufu.png") as Texture2D if index == 0 else TofufuTestArt.thumbnail(TofufuTestArt.IDS[index - 1])

func _new_room() -> void:
	if room != null:
		remove_child(room)
		room.queue_free()
	room = BattleRoom.new()
	var name_text := GamePreferences.clean_nickname(panel.nickname.text)
	room.nickname = name_text if not name_text.is_empty() else "Tofufu"
	app.preferences.remember_nickname(room.nickname)
	room.skin = _skin
	room.options = _options.duplicate()
	room.send_packet = transport.send_packet
	room.send_batch = transport.send_packets
	room.gameplay.connect(rounds.receive)
	room.changed.connect(_refresh)
	room.started.connect(_start)
	room.ended.connect(_ended)
	add_child(room)

func _connect(next_channel: String, automatic: bool, target: String) -> void:
	_host_pending = not automatic and target.is_empty()
	transport.close()
	_new_room()
	channel = next_channel
	transport.discovery_channel = "tofufu-battle-v1/" + channel
	room.auto_queue = automatic
	room.target_host = target
	room.phase = "connecting"
	room.deadline = room.clock + 15
	room.status = "Finding reachable Battle Royale players…"
	transport.start(room.nickname)
	_refresh()

func _practice() -> void:
	if not BattleOptions.playable(_options, 1): return
	_new_room()
	room.practice()

func _join_invite(code: String) -> void:
	var parts := code.strip_edges().split(":")
	if parts.size() != 3 or parts[0] != "TOFUBR1" or not BattleProtocol.token(parts[1]) or not BattleProtocol.key(parts[2]):
		panel.status.text = "This Battle Royale invite is invalid. Copy the complete invite from your friend."
		return
	_host_pending = false
	_connect(parts[1], false, parts[2])

func _copy_invite() -> void:
	if room == null or not room.authority() or not BattleProtocol.token(channel): return
	DisplayServer.clipboard_set("TOFUBR1:" + channel + ":" + room.local_key)
	panel.status.text = "Invite copied · Send it to your friends"

func _receive(event: Dictionary) -> void:
	if room == null: return
	room.receive(event)
	if event.get("type") == "ready" and _host_pending:
		_host_pending = false
		room.host()
	_refresh()

func _refresh() -> void:
	BattleLobbyState.refresh(self)

func _start() -> void:
	if _loading: return
	if is_instance_valid(game):
		if game.match_state.winner == -2 and not room.offline: return
		_clear_game()
	rounds.begin(room.epoch)
	_loading = true
	_generation += 1
	var generation := _generation
	if is_instance_valid(panel): panel.status.text = "Building the Battle Royale map…"
	loading_view.begin(tr("Battle Royale"), not room.offline)
	loading_view.stage("Building the Battle Royale map…", 30)
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _generation: return
	app.menu.hide()
	game = BattleRoyaleGame.new()
	game.room = room
	game.preferences = app.preferences
	game.replay_requested.connect(rounds.request)
	game.leave_requested.connect(leave)
	game.prepared.connect(func() -> void:
		game.match_view.career = rounds.career
		loading_view.hide())
	add_child(game)
	_loading = false

func _ended(reason: String) -> void:
	loading_view.hide()
	_generation += 1
	_loading = false
	_clear_game()
	transport.close()
	app.menu.show()
	show_lobby()
	panel.status.text = tr(reason)

func _clear_game() -> void:
	if not is_instance_valid(game): return
	rounds.settle()
	remove_child(game)
	game.queue_free()
	game = null

func leave() -> void:
	loading_view.hide()
	_generation += 1
	_loading = false
	_clear_game()
	if room != null:
		room.broadcast({"kind": "br_leave", "epoch": room.epoch, "term": room.term})
		remove_child(room)
		room.queue_free()
		room = null
	_clear_game()
	transport.close()
	_host_pending = false
	app.menu.show()
	app._home()

func shutdown() -> void:
	leave()
	await transport.shutdown()

func _process(_delta: float) -> void:
	rounds.update(_delta)
	if room != null and room.phase == "waiting" and room.auto_queue and int(room.clock) != _last_lobby_second:
		_last_lobby_second = int(room.clock)
		_refresh()

func _exit_tree() -> void:
	transport.close()
