extends SceneTree
## Run only through tools/verify_coop.py: separate processes, real Holepunch streams.

var room := PlaytestRoom.new()
var bridge := HolepunchTransport.new()
var session: CoopSession
var game: Node3D
var source: CoopTestInput
var role: String
var directory: String
var started_at: int = 0
var synced_at: int = 0
var guest_key: String = ""
var departed: bool = false
var rejoined_at: int = 0
var _dropped: bool = false
var _picked_up: bool = false
var _bean: bool = false
var failures: int = 0
var closing: bool = false
var debug_at: int = 0
var _chat_sent: bool = false
var _voice_received: bool = false

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	role = OS.get_environment("TOFUFU_TEST_ROLE")
	# A slower host must not accumulate the guest's 60-Hz input as tick debt.
	if role == "host": Engine.physics_ticks_per_second = 30
	directory = OS.get_environment("TOFUFU_TEST_DIRECTORY")
	check(not directory.is_empty(), "integration test directory supplied")
	if directory.is_empty(): quit(1); return
	bridge.identity_path = directory.path_join("host.key" if role == "host" else "guest.key")
	root.add_child(bridge)
	root.add_child(room)
	room.send_packet = bridge.send_packet
	bridge.event_received.connect(room.receive)
	bridge.event_received.connect(func(event: Dictionary) -> void:
		if event.get("type") == "packet" and event.data.get("type") in ["welcome", "begin", "ready", "leave"]:
			print(role, " event ", event.data.type, " members=", room.members.size(), " playing=", room.playing))
	room.changed.connect(_changed)
	room.started.connect(_start)
	room.ended.connect(func(reason: String) -> void:
		if not closing: check(false, "session stays connected until explicit shutdown: " + reason))
	bridge.start("Host" if role == "host" else "Guest")
	var deadline := Time.get_ticks_msec() + 50000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if Time.get_ticks_msec() - debug_at > 5000:
			debug_at = Time.get_ticks_msec()
			print(role, " state session=", session != null, " status=", room.status)
			if session != null: print("sync=", session._synchronized, " seq=", session._snapshot_sequence, " ready=", session._ready_peers.size())
		if session == null: continue
		if role == "host":
			if _host_step(): break
		elif _guest_step(): break
	check(Time.get_ticks_msec() < deadline, "two-process session completes before timeout")
	var stats := {"role": role, "key": room.local_key, "failures": failures, "latency_ms": session.latency_ms if session != null else -1}
	if game != null:
		stats.beans = game.encounters.beans
		stats.hits = game.encounters.dummy_nodes[0].hit_count
	var file := FileAccess.open(directory.path_join(role + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(stats))
	file.close()
	closing = true
	room.leave()
	bridge.close()
	var close_deadline := Time.get_ticks_msec() + 2500
	while not bridge._retiring.is_empty() and Time.get_ticks_msec() < close_deadline: await process_frame
	check(bridge._retiring.is_empty(), "sidecar shuts down")
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Holepunch ", role, ": ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func _changed() -> void:
	if closing or room.local_key.is_empty(): return
	if role == "host":
		if not room.hosting: room.create_room()
		elif not room.playing: room.begin()
	elif not room.playing and room.host_key.is_empty() and room._pending.is_empty():
		for key: String in room.peers:
			if room.peers[key].hosting:
				room.join_room(key)
				break

func _start(_hosting: bool, _members: Array, _local: String) -> void:
	game = load("res://game/app/main.tscn").instantiate()
	game.play_opening = role != "host"
	root.add_child(game)
	session = CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	started_at = Time.get_ticks_msec()
	if role == "host":
		(session.roster.local_input as LocalPlayerInput).enabled = false

	else:
		source = CoopTestInput.new()
		root.add_child(source)
		session.roster.local_input = source

func _host_step() -> bool:
	if guest_key.is_empty():
		if room.members.size() < 2: return false
		for key: String in room.members:
			if key == room.local_key: continue
			guest_key = key
			var member := session.roster.party[key]
			member.actor.position = game.encounters.dummy_nodes[0].position + Vector3(0, 0.05, 1.4)
			member.health.current = 80
			game.player.position = member.actor.position + Vector3(-4, 0, 0)
		started_at = Time.get_ticks_msec()

	if game.chat.voice._speakers.has(guest_key): _voice_received = true
	var elapsed := (Time.get_ticks_msec() - started_at) / 1000.0
	if elapsed > 1.4 and not _bean and session.roster.party.has(guest_key):
		_bean = true
		var bean: SoybeanPickup = game.encounters.add_pickup(game.encounters.next_pickup_id, session.roster.actors[guest_key].position)
		bean._age = 1
	if not session.roster.party.has(guest_key): departed = true
	elif departed and rejoined_at == 0: rejoined_at = Time.get_ticks_msec()
	if rejoined_at == 0 or not FileAccess.file_exists(directory.path_join("returning.json")): return false
	check(game.chat.view.history.has("Guest: Peer hello"), "text delivered over real Holepunch stream")
	check(_voice_received, "synthetic voice reached host playback over real Holepunch stream")
	check(game.encounters.dummy_nodes[0].hit_count >= 1, "real guest attack reached host collision simulation")
	check(game.encounters.beans == 1, "real guest collected once")
	check(session.roster.saved_states.has(guest_key), "departed guest state retained")
	var store := SaveStore.new()
	store.directory = directory.path_join("saves")
	store.extra_validator = CoopCheckpoint.valid
	var record := AdventureSnapshot.capture(game, "Two-process co-op", elapsed)
	record.coop = CoopCheckpoint.capture(session)
	check(store.write_slot(0, record), "host co-op save persisted")
	check(store.read_slot(0).coop.party.has(guest_key), "stable guest identity in saved party")
	return true

func _guest_step() -> bool:
	if not session._synchronized: return false
	if synced_at == 0: synced_at = Time.get_ticks_msec()
	var elapsed := (Time.get_ticks_msec() - synced_at) / 1000.0
	if elapsed > 0.5 and not _chat_sent:
		_chat_sent = true
		game.chat._submit("Peer hello", false)
		var samples := PackedVector2Array()
		samples.resize(4800)
		game.chat._captured(ProximityVoice.encode(samples))
	if role == "guest":
		source.attack = elapsed < 0.25
		source.move = Vector2.RIGHT if elapsed > 2.1 and elapsed < 2.5 else Vector2.ZERO
		if elapsed > 0.8 and not _dropped:
			_dropped = true
			source.drop = true
		if elapsed > 1.1 and not _picked_up:
			_picked_up = true
			source.pickup = true
		if elapsed < 4.5: return false
	else:
		if elapsed < 2: return false
	var member := session.roster.party[room.local_key]
	check(game.encounters.dummy_nodes[0].hit_count >= 1, "host dummy feedback replicated")
	check(game.encounters.beans == 1 and member.inventory.count_item("edamame") >= 1, "replicated loot goes to inventory")
	check(member.combat.equipment.knife_owned, "equipped knife survives network/reconnect")
	print(role, " position=", member.actor.position, " target=", member.target_state.get("position", []))
	check(member.actor.position.x > game.encounters.dummy_nodes[0].position.x + 0.5, "remote movement/reconnect position")
	return true
