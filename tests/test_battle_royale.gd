extends SceneTree
## Bounded admission, synchronized starts, match rules and peer input ownership.

var failures: int = 0
var rooms: Array[BattleRoom] = []
var batches: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	_rules()
	_input_buffer()
	_protocol()
	await _rooms()
	_ownership()
	await _lobby()
	for room: BattleRoom in rooms: room.queue_free()
	await process_frame
	print("Battle Royale rules/session: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _state(humans: int = 1) -> BattleMatch:
	var state := BattleMatch.new()
	var positions: Array[Vector3] = []
	for i in 20: positions.append(Vector3(i, 0, 0))
	state.initialize(positions, humans, [20 - humans, 1])
	return state

func _rules() -> void:
	var state := _state()
	check(state.rows.size() == 20 and state.rows[0][17] == 0 and state.rows[19][17] == 1, "exact 20 seats with CPU fill")
	state.hit(0, 100, 1)
	check(state.rows[0][8] == 100, "deployment immunity")
	state.time = 13
	state.rows[0][9] = 50
	state.hit(0, 70, 1)
	check(state.rows[0][8] == 80 and state.rows[0][9] == 0, "armour absorbs ordinary damage")
	state.rows[0][9] = 50
	state.hit(0, 10, -1, true)
	check(state.rows[0][8] == 70 and state.rows[0][9] == 50, "storm ignores armour")
	state.heal(0)
	check(state.rows[0][8] == 100 and state.rows[0][16] == 0, "healing uses match resources")
	state.loot = [[0, 0.0, 0.0, 0.0, 6, 1], [1, 0.0, 0.0, 0.0, 2, 1]]
	state.use_loot(0)
	check(state.rows[0][10] == 4 and state.rows[0][22] == 4 and state.rows[0][23] == 2 and state.loot[0][5] == 0, "scavenge adventure Nori and keep ranged slot")
	check(state.loot.size() == 3 and state.loot[2][4] == 0, "replaced melee weapon drops for another survivor")
	state.use_loot(0)
	check(state.rows[0][9] == 100, "armour pickup bounded to 100")
	state.hit(0, 200, 1)
	state.hit(0, 200, 1)
	check(state.alive == 19 and state.rows[0][13] == 20 and state.rows[1][12] == 1, "elimination, placement and kill credit happen once")
	check(state.loot.size() == 4, "defeat drops scavenged weapon")
	for slot in range(2, 20): state.hit(slot, 200, 1)
	state.step(0.02)
	check(state.winner == 1 and state.rows[1][13] == 1 and state.alive == 1, "last survivor wins")
	var ended := state.capture()
	state.hit(1, 100, 0)
	state.step(1)
	check(state.rows == ended.actors and state.time == ended.time, "finished match is immutable")
	var last := 1000.0
	for tick in 5000:
		var radius := BattleRing.radius(tick * 0.1)
		check(radius <= last, "safe zone never expands")
		last = radius
	check(last == 0 and BattleRing.outside(Vector3.ZERO, 500), "final storm closes completely")

func _input_buffer() -> void:
	var buffer := BattleInputBuffer.new()
	buffer.accept(0, [1.0, 0.0, 0.0, 1.0, 24], 0)
	check(buffer.sample(0, 0.09)[0] == 0, "host and guests wait the same minimum delay")
	var command := buffer.sample(0, 0.11)
	check(command[0] == 1 and command[4] == 24, "due movement and press edges are consumed")
	check(buffer.sample(0, 0.12)[4] == 0, "press edge never repeats")
	check(buffer.sample(0, 0.5)[0] == 0, "stale held intent expires")
	for i in 30: buffer.accept(1, [0.0, 1.0, 1.0, 0.0, 0], 1)
	check(buffer.queues[1].size() <= 8, "per-actor delay queue stays bounded")

func _protocol() -> void:
	check(BattleProtocol.command([1.0, 0.0, 1.0, 0.0, 255]), "bounded command accepted")
	check(not BattleProtocol.command([1.0, 1.0, 0.0, 1.0, 0]), "diagonal speed hack rejected")
	check(not BattleProtocol.command([NAN, 0.0, 1.0, 0.0, 0]), "nonfinite command rejected")
	check(not BattleProtocol.command([0, 0, 0, 1, 2097152]), "unknown intent bits rejected")
	var state := _state()
	var packet := state.capture()
	check(BattleProtocol.snapshot(packet), "complete bounded state accepted")
	packet.actors[0][8] = 101
	check(not BattleProtocol.snapshot(packet), "out of range health rejected")
	packet.actors[0][8] = "100"
	check(not BattleProtocol.snapshot(packet), "wrong nested type rejected")
	check(not BattleProtocol.roster([{"key": "a".repeat(64), "name": "Fufu", "skin": 8}]), "unknown character rejected")

func _rooms() -> void:
	for i in 21:
		var room := BattleRoom.new()
		root.add_child(room)
		room.local_key = "%064x" % (i + 1)
		room.nickname = "Bean %d" % i
		room.send_packet = func(key: String, data: Dictionary) -> void: _deliver(room.local_key, key, data)
		rooms.append(room)
	for room: BattleRoom in rooms:
		for other: BattleRoom in rooms:
			if other != room: room.receive({"type": "peer", "key": other.local_key, "name": other.nickname})
	var host := rooms[0]
	host.send_batch = func(keys: Array[String], packet: Dictionary) -> void:
		batches += 1
		for key: String in keys: _deliver(host.local_key, key, packet)
	host.host()
	host.receive({"type": "packet", "key": rooms[1].local_key, "data": {"kind": "br_join", "v": BattleProtocol.VERSION, "build": BattleProtocol.BUILD + 1, "skin": 0}})
	check(host.members.size() == 1, "incompatible world builds cannot enter the same match")
	rooms[1].auto_queue = true
	rooms[1].host()
	host.advertise(rooms[1].local_key)
	rooms[1]._process(0.1)
	check(rooms[1].host_key == host.local_key and rooms[1].epoch == host.epoch, "simultaneous empty public hosts consolidate into the same epoch")
	for i in range(1, 21): rooms[i].join(host.local_key)
	check(host.members.size() == 20, "twentieth seat admitted; twenty-first rejected")
	check(rooms[19].members.size() == 20 and rooms[20].members.is_empty(), "roster replicated to admitted participants only")
	host.begin()
	check(host.phase == "loading" and rooms[1].phase == "loading", "match prepares before combat starts")
	check(batches > 0 and rooms[19].phase == "loading", "batched broadcast reaches every admitted room")
	for i in 19: rooms[i].loaded()
	check(host.phase == "loading", "authority waits for last peer readiness")
	rooms[19].loaded()
	check(host.phase == "playing" and rooms[19].phase == "playing", "all prepared peers start together")
	rooms[1].receive({"type": "packet", "key": host.local_key, "data": {"kind": "br_go", "epoch": "b".repeat(24)}})
	check(rooms[1].epoch == host.epoch, "wrong epoch cannot replace active session")
	rooms[1].receive({"type": "left", "key": host.local_key})
	check(rooms[1].phase == "ended", "host loss before the first checkpoint ends cleanly")
	await process_frame

func _deliver(from: String, to: String, packet: Dictionary) -> void:
	for room: BattleRoom in rooms:
		if room.local_key == to:
			room.receive({"type": "packet", "key": from, "data": JSON.parse_string(JSON.stringify(packet))})
			return

func _ownership() -> void:
	var game := BattleRoyaleGame.new()
	game.room = rooms[0]
	game.match_state = _state(20)
	game.replication.game = game
	var net := game.replication
	net.receive(rooms[1].local_key, {"kind": "br_input", "epoch": game.room.epoch, "term": game.room.term, "seq": 1, "inputs": [[0, [1, 0, 1, 0, 0]]]})
	check(net.last_sequences.is_empty(), "peer cannot control another human")
	net.receive(rooms[1].local_key, {"kind": "br_input", "epoch": game.room.epoch, "term": game.room.term, "seq": 1, "inputs": [[1, [1, 0, 1, 0, 0]]]})
	check(net.last_sequences.get(rooms[1].local_key) == 1, "authenticated owner controls its seat")
	net.receive(rooms[1].local_key, {"kind": "br_input", "epoch": game.room.epoch, "term": game.room.term, "seq": 1, "inputs": [[1, [-1, 0, 1, 0, 0]]]})
	check(game.simulation.buffer.queues[1].size() == 1, "replayed inputs are discarded")
	game.match_state.rows[19][17] = 1
	var assigned := net.owner_of(19, net.workers())
	var foreign := rooms[1].local_key if assigned != rooms[1].local_key else rooms[2].local_key
	net.receive(foreign, {"kind": "br_input", "epoch": game.room.epoch, "term": game.room.term, "seq": 2, "inputs": [[19, [1, 0, 1, 0, 0]]]})
	check(not game.simulation.buffer.queues.has(19), "CPU shard accepts only its assigned worker")
	game.free()

func _lobby() -> void:
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	var fake: SessionTransport = load("res://tests/lobby_test_transport.gd").new()
	app.get_node("BattleTransport").free()
	app.add_child(fake)
	app.battle_transport = fake
	app.preferences.path = "user://battle-lobby-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(app)
	await process_frame
	app.battle.show_lobby()
	for dimensions in [Vector2i(640, 360), Vector2i(1280, 720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for i in 3: await process_frame
		check(app.menu.content.size.x <= dimensions.x - 30, "battle lobby fits viewport width")
	check(fake.starts == 0, "opening battle menu leaves networking opt-in")
	check(app.battle.panel.picker.item_count == 8, "all embedded appearances are selectable")
	app.battle._join_invite("bad invitation")
	check(fake.starts == 0, "malformed invitation never starts a runtime")
	app.battle.panel.host_friends.emit()
	check(fake.starts == 1 and app.battle.room.authority() and BattleProtocol.token(app.battle.channel), "private room starts isolated discovery and creates invite topic")
	app.battle.room._process(31)
	check(app.battle.room.phase == "waiting", "private room waits for creator instead of auto-starting")
	app.battle.leave()
	check(fake.is_closed() and app.battle.game == null and app.menu.visible, "battle exit closes its own transport and returns home")
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
