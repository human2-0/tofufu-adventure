extends SceneTree
## Private callouts: authenticated identities, range, rate/replay limits and expiry.
var failures: int = 0
var sent: Array = []

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", label)

func _run() -> void:
	var fixture := Node3D.new()
	root.add_child(fixture)
	var game := BattleRoyaleGame.new()
	game.room = BattleRoom.new()
	root.add_child(game.room)
	game.room.phase = "playing"
	game.room.epoch = "a".repeat(24)
	game.room.options = [0, 1, 1]
	game.room.local_key = "%064x" % 1
	game.room.host_key = game.room.local_key
	game.room.send_packet = func(key: String, packet: Dictionary) -> void: sent.append([key, packet.duplicate(true)])
	game.playing = true
	var positions: Array[Vector3] = []
	for index in 4:
		var key := "%064x" % (index + 1)
		game.room.members.append({"key": key, "name": "Friend %d" % index, "skin": 0})
		game.room.connected[key] = true
		var body := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
		body.position = Vector3(index * 20, 0, 0)
		positions.append(body.position)
		fixture.add_child(body)
		body.set_physics_process(false)
		game.bodies.append(body)
	game.match_state.initialize(positions, 4, [0, 1, 1])
	game.hud = BattleHUD.new()
	fixture.add_child(game.hud)
	var pings := BattleSquadPings.new()
	pings.game = game
	fixture.add_child(pings)
	var packet := {"kind": "br_ping", "epoch": game.room.epoch, "term": 0, "seq": 1, "at": [45, 0, 2], "danger": false}
	pings.receive(game.room.members[2].key, packet)
	check(sent.size() == 2 and sent[0][0] == game.room.members[2].key and sent[1][0] == game.room.members[3].key, "only the sending duo receives its callout")
	check(game.hud.radar.squad_pings.is_empty(), "enemy callouts never enter the local radar")
	sent.clear()
	packet.at = [22, 0, 4]
	pings.receive(game.room.members[1].key, packet)
	check(game.hud.radar.squad_pings == [Vector3(22, 4, 0)] and sent.size() == 1, "ally point is shared privately with a stationary world/map marker")
	packet.seq = 2
	packet.at = [23, 0, 5]
	pings.receive(game.room.members[1].key, packet)
	check(game.hud.radar.squad_pings[0].x == 22, "one-second callout rate limit prevents spam")
	pings._process(1.01)
	packet.danger = true
	pings.receive(game.room.members[1].key, packet)
	check(game.hud.radar.squad_pings == [Vector3(23, 5, 1)], "new danger replaces the same sender's marker")
	packet.at = [900, 0, 0]
	packet.seq = 3
	pings._process(1.01)
	pings.receive(game.room.members[1].key, packet)
	check(game.hud.radar.squad_pings[0].x == 23, "out-of-range callouts are rejected by the host")
	packet.at = [20, 0, 0]
	packet.epoch = "b".repeat(24)
	pings.receive(game.room.members[1].key, packet)
	check(game.hud.radar.squad_pings[0].x == 23, "stale round callouts cannot leak into another match")
	packet.epoch = game.room.epoch
	packet.kind = "br_ping_event"
	packet.slot = 1
	pings.receive(game.room.members[2].key, packet)
	check(game.hud.radar.squad_pings[0].x == 23, "an enemy cannot spoof an authoritative ally event")
	pings._process(8.01)
	check(game.hud.radar.squad_pings.is_empty(), "shared callouts expire after eight seconds")
	pings.clear()
	check(pings._events.is_empty() and pings._last.is_empty(), "migration discards transient callouts and old term sequences")
	pings.free()
	fixture.queue_free()
	game.room.queue_free()
	game.free()
	await process_frame
	await create_timer(0.25).timeout
	print("Battle private squad callouts: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
