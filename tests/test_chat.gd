extends SceneTree
## Real scene + JSON-wire routing tests, without microphone hardware or external peers.

var delivered: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_rules()
	var room := PlaytestRoom.new()
	room.local_key = "a".repeat(64)
	room.host_key = room.local_key
	room.hosting = true
	room.playing = true
	room.epoch = "c".repeat(32)
	var near_key := "b".repeat(64)
	var far_key := "d".repeat(64)
	room.members = [room.local_key, near_key, far_key]
	room.names = {room.local_key: "Host", near_key: "Mame", far_key: "Bean"}
	room.peers = {near_key: {"name": "Mame"}, far_key: {"name": "Bean"}}
	room.send_packet = func(key: String, data: Dictionary) -> void:
		delivered.append({"key": key, "data": JSON.parse_string(JSON.stringify(data))})
	root.add_child(room)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	var session := CoopSession.new()
	session.room = room
	session.game = game
	game.add_child(session)
	session.set_physics_process(false)
	var chat: ProximityChat = game.chat
	game.player.position = Vector3.ZERO
	session.roster.actors[near_key].position = Vector3(8, 0, 0)
	session.roster.actors[far_key].position = Vector3(30, 0, 0)
	chat._submit("Hello [b]beans[/b]!", false)
	assert(delivered.size() == 1 and delivered[0].key == near_key, "normal chat excludes distant peers")
	assert(chat.view.history.size() == 1 and chat._bubbles.size() == 1)
	delivered.clear()
	chat._rules.forget(room.local_key)
	chat._submit("Come to the bridge!", true)
	assert(delivered.size() == 2, "yelling reaches farther players")
	assert(chat.view.history[-1].contains("[YELL]"))
	delivered.clear()
	var data := {"type": "chat_text", "text": "I am Mame", "yell": false, "sequence": 1, "sender": far_key, "epoch": room.epoch}
	room.receive({"type": "packet", "key": near_key, "data": data})
	assert(chat.view.history[-1].begins_with("Mame:"), "authenticated sender overrides forged identity")
	var size := chat.view.history.size()
	room.receive({"type": "packet", "key": near_key, "data": data})
	assert(chat.view.history.size() == size, "duplicate rejected")
	data.sequence = 2
	data.epoch = "stale"
	room.receive({"type": "packet", "key": near_key, "data": data})
	assert(chat.view.history.size() == size, "stale epoch rejected")
	delivered.clear()
	var audio := PackedVector2Array()
	audio.resize(4800)
	audio.fill(Vector2(0.25, 0.25))
	chat._captured(ProximityVoice.encode(audio))
	assert(delivered.size() == 1 and delivered[0].key == near_key, "voice stays nearby and never echoes to sender")
	var decoded := ProximityVoice.decode(delivered[0].data.pcm)
	assert(decoded.size() == 1600 and absf(decoded[0].x - 0.25) < 0.001)
	chat.voice.enable_microphone(true)
	assert(is_instance_valid(chat.voice._microphone) and not chat.voice._microphone.playing)
	chat.voice.enable_microphone(false)
	assert(AudioServer.get_bus_index(chat.voice._bus_name) == -1)
	chat.voice.receive(near_key, delivered[0].data.pcm, chat._gain(near_key))
	assert(chat.voice._speakers.has(near_key), "received audio creates playback")
	chat.voice.set_gain(near_key, 0)
	assert(not chat.voice._speakers.has(near_key), "walking out of range stops buffered voice")
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	chat.view._input(enter)
	assert(chat.view.editing and (session.roster.local_input as LocalPlayerInput).chat_blocked)
	Input.action_press("move_right")
	Input.action_press("attack")
	var command := session.roster.local_input.sample(Vector3.ZERO)
	assert(command.move == Vector2.ZERO and not command.attack_held and command.cancel_actions)
	Input.action_release("move_right")
	Input.action_release("attack")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	chat.view._input(escape)
	assert(not chat.view.editing and not (session.roster.local_input as LocalPlayerInput).chat_blocked)
	chat.set_menu_open(true)
	chat.view._input(enter)
	assert(not chat.view.editing)
	for index in 60: chat.view.show_message("You", str(index), false)
	assert(chat.view.history.size() == 50 and chat.view.history[0] == "You: 10")
	var bubble: SpeechBubble = chat._bubbles[room.local_key]
	bubble._process(7)
	assert(bubble.is_queued_for_deletion(), "bubble expires")
	game.queue_free()
	room.queue_free()
	await process_frame
	print("Proximity chat: PASS")
	quit()

func _rules() -> void:
	var rules := ProximityRules.new()
	var text := {"type": "chat_text", "text": "Hi", "yell": false, "sequence": 1}
	assert(rules.accept("a", text, 0))
	text.sequence = 2
	assert(not rules.accept("a", text, 699))
	assert(rules.accept("a", text, 700))
	assert(not rules.accept("a", text, 1400))
	text.sequence = NAN
	assert(not ProximityRules.valid(text))
	text.sequence = 3
	text.text = "a".repeat(241)
	assert(not ProximityRules.valid(text))
	text.text = "\n\t"
	assert(not ProximityRules.valid(text))
	assert(ProximityRules.nearby(Vector3.ZERO, Vector3(12, 100, 0)))
	assert(not ProximityRules.nearby(Vector3.ZERO, Vector3(12.1, 0, 0)))
	assert(not ProximityRules.nearby(Vector3.ZERO, Vector3(36.1, 0, 0), true))
	assert(not ProximityRules.valid({"type": "chat_voice", "sequence": 1, "pcm": "A".repeat(10)}))

	var frames := PackedVector2Array()
	frames.resize(1600)
	var voice := {"type": "chat_voice", "sequence": 1, "pcm": ProximityVoice.encode(frames)}
	for index in 3:
		voice.sequence = index + 1
		assert(rules.accept("voice", voice, 0), "bounded coalesced audio burst accepted")
	voice.sequence = 4
	assert(not rules.accept("voice", voice, 0), "voice flood rejected")
	assert(rules.accept("voice", voice, 100), "voice token replenished")
	voice.pcm = "!".repeat(4268)
	assert(not ProximityRules.valid(voice))
