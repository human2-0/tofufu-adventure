class_name ProximityChat
extends Node
## Composes chat intent, host distance routing and actor-local presentation.

var game: Node3D
var room: PlaytestRoom
var roster: CoopRoster
var view := ChatView.new()
var voice := ProximityVoice.new()
var _rules := ProximityRules.new()
var _received := ProximityRules.new()
var _sequence: int = 0
var _bubbles: Dictionary = {}
var _menu_open: bool = false
var _members: Array = []

func _ready() -> void:
	add_child(view)
	add_child(voice)
	view.submitted.connect(_submit)
	view.editing_changed.connect(_editing)
	view.microphone.toggled.connect(voice.enable_microphone)
	voice.captured.connect(_captured)

func connect_session(session_room: PlaytestRoom, session_roster: CoopRoster) -> void:
	room = session_room
	_members = room.members.duplicate()
	roster = session_roster
	room.gameplay_packet.connect(_packet)
	roster.changed.connect(_members_changed)
	view.microphone.disabled = false

func set_menu_open(active: bool) -> void:
	_menu_open = active
	view.available = not active
	view.visible = not active
	if active:
		view.set_editing(false)
		voice.set_talking(false)

func _editing(active: bool) -> void:
	var source := (roster.local_input if roster != null else game.player.command_source) as LocalPlayerInput
	if source != null: source.chat_blocked = active
	if active:
		game.player.motor.cancel_jump()
		game.combat.reset()

func _submit(message: String, yelled: bool) -> void:
	_send({"type": "chat_text", "text": message, "yell": yelled})

func _captured(pcm: String) -> void:
	_send({"type": "chat_voice", "pcm": pcm})

func _send(data: Dictionary) -> void:
	_sequence += 1
	data.sequence = _sequence
	if room == null:
		if _rules.accept("local", data, Time.get_ticks_msec()): _display("local", data)
	elif room.playing:
		if room.hosting: _route(room.local_key, data)
		else: room.send_game(room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if data.get("type") not in ["chat_text", "chat_voice"]: return
	if room.hosting:
		_route(key, data)
	elif key == room.host_key and data.get("sender") is String and data.sender in room.members:
		if _received.accept(data.sender, data, Time.get_ticks_msec(), false): _display(data.sender, data)

func _route(sender: String, data: Dictionary) -> void:
	if sender not in roster.actors or not _rules.accept(sender, data, Time.get_ticks_msec()): return
	var packet := {"type": data.type, "sequence": data.sequence, "sender": sender}
	if data.type == "chat_text":
		packet.text = ProximityRules.clean(data.text)
		packet.yell = data.yell
	else: packet.pcm = data.pcm
	for key: String in roster.actors:
		if data.type == "chat_voice" and key == sender: continue
		if not ProximityRules.nearby(roster.actors[sender].position, roster.actors[key].position, packet.get("yell", false)): continue
		if key == room.local_key: _display(sender, packet)
		else: room.send_game(key, packet.duplicate())

func _display(key: String, data: Dictionary) -> void:
	if data.type == "chat_voice":
		voice.receive(key, data.pcm, _gain(key))
		return
	var actor: Node3D = game.player if roster == null else roster.actors.get(key)
	if not is_instance_valid(actor): return
	var speaker := "You" if room == null or key == room.local_key else ProximityRules.clean(str(room.names.get(key, "Fufu")))
	view.show_message(speaker, data.text, data.yell)
	if is_instance_valid(_bubbles.get(key)): _bubbles[key].queue_free()
	var bubble := SpeechBubble.new()
	bubble.yelled = data.yell
	bubble.text = ("YELL! " if data.yell else "") + ProximityRules.clean(data.text)
	bubble.modulate = Color("ffdb8a") if data.yell else Color.WHITE
	actor.add_child(bubble)
	_bubbles[key] = bubble

func _gain(key: String) -> float:
	if roster == null or key not in roster.actors: return 0
	var offset: Vector3 = roster.actors[key].position - game.player.position
	return clampf(1.0 - Vector2(offset.x, offset.z).length() / ProximityRules.NEAR, 0, 1)

func _process(_delta: float) -> void:
	voice.listening = view.listening.button_pressed
	var online := room != null and room.playing
	var talking := online and not _menu_open and not view.editing and view.microphone.button_pressed and Input.is_physical_key_pressed(KEY_V) and DisplayServer.window_is_focused()
	voice.set_talking(talking)
	view.status.text = "NEARBY · " + ("Talking… (12u)" if talking else ("Enter to chat · 12u / yell 36u" if online else "Enter to chat · Offline"))
	if roster != null:
		for key: String in roster.actors: voice.set_gain(key, _gain(key))
	for key: String in _bubbles.keys():
		if not is_instance_valid(_bubbles[key]): _bubbles.erase(key)
		elif roster != null and key in roster.actors:
			_bubbles[key].visible = ProximityRules.nearby(game.player.position, roster.actors[key].position, _bubbles[key].yelled)

func _members_changed() -> void:
	for key: String in _bubbles.keys():
		if key not in room.members:
			if is_instance_valid(_bubbles[key]): _bubbles[key].queue_free()
			_bubbles.erase(key)
	for key: String in _members:
		if key not in room.members:
			_rules.forget(key)
			_received.forget(key)
			voice.forget(key)
	_members = room.members.duplicate()
