extends SceneTree
## Authenticated fake mesh with JSON framing, loss/partitions and bounded recovery.
var failures: int = 0
var rooms: Array[BattleRoom] = []
var blocked: Array[String] = []
var split: bool = false
var restores: Dictionary = {}
var outcomes: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", label)

func _run() -> void:
	await _mesh(2)
	var first := rooms[1]
	var original := first.migration.checkpoint
	_drop(0)
	check(first.phase == "recovering", "authority loss immediately pauses instead of destroying the match")
	_ticks(4)
	check(first.phase == "playing" and first.authority() and first.term == 1, "sole surviving human becomes authority and resumes")
	check(restores.get(first.local_key, {}).get("seq") == 1, "replacement restores the shared checkpoint before resuming")
	check(first.migration.checkpoint == original, "election leaves the shared gameplay state intact")
	first.receive({"type": "peer", "key": rooms[0].local_key, "name": "Former host"})
	first.gameplay.connect(func(_key: String, _packet: Dictionary) -> void: outcomes += 1)
	_deliver(rooms[0].local_key, first.local_key, {"kind": "br_state", "epoch": first.epoch, "term": 0})
	check(outcomes == 0, "late old-term outcomes cannot enter the resumed match")
	await _mesh(4)
	rooms[0].receive({"type": "packet", "key": rooms[1].local_key, "data": {"kind": "br_migrate", "epoch": rooms[0].epoch, "term": 0, "attempt": 0}})
	check(rooms[0].phase == "playing", "healthy authority ignores a lone unsupported recovery request")
	rooms[1].receive({"type": "left", "key": rooms[0].local_key})
	_ticks(0.6)
	check(rooms[0].phase == "playing" and rooms[2].phase == "playing" and rooms[3].phase == "playing", "one guest's bad host link cannot pause healthy peers")
	rooms[2].receive({"type": "left", "key": rooms[0].local_key})
	_ticks(0.7)
	check(rooms[0].phase == "recovering" and rooms[3].phase == "recovering", "a majority of authenticated suspicions brings every reachable peer into recovery")
	await _mesh(4)
	rooms[3].migration.remember(_checkpoint(rooms[0], 3)) # Only one survivor saw the newest host checkpoint.
	_drop(0)
	_ticks(4)
	for i in range(1, 4):
		check(rooms[i].host_key == rooms[1].local_key and rooms[i].phase == "playing", "all survivors agree on one host")
		check(rooms[i].migration.checkpoint_seq == 3 and restores.get(rooms[i].local_key, {}).get("seq") == 3, "every peer retains the agreed newest checkpoint for further migration")
	var new_host := rooms[1]
	new_host.migration.publish(_checkpoint(new_host, 4))
	_drop(1)
	_ticks(4)
	for i in range(2, 4):
		check(rooms[i].host_key == rooms[2].local_key and rooms[i].term == 2 and rooms[i].phase == "playing", "a second host loss migrates the same match again")
	await _mesh(5)
	_drop(0)
	_drop(1)
	_ticks(9)
	for i in range(2, 5):
		check(rooms[i].phase == "playing" and rooms[i].host_key == rooms[2].local_key, "unavailable first candidate is skipped in the next bounded ballot")
	await _mesh(3)
	_drop(0)
	_ticks(1.8)
	check(rooms[2].migration.election.committed and rooms[2].phase == "recovering", "survivors restore before the countdown finishes")
	_drop(1)
	check(rooms[2].phase == "ended", "replacement loss during a committed handoff fails safely")
	await _mesh(4)
	_drop(0)
	_ticks(1.1)
	var locked := rooms[2].migration.vote_lock
	check(not locked.is_empty(), "a proposal locks each peer to one replacement for this loss episode")
	rooms[2].migration.advance(1)
	rooms[2].migration.election.receive(rooms[2].migration, rooms[2].local_key,
		{"kind": "br_mproposal", "blob": rooms[2].migration.checkpoint})
	rooms[2].migration.election.repeat(rooms[2].migration)
	check(rooms[2].migration.vote_lock == locked and not rooms[2].migration.election.votes.has(rooms[2].local_key), "later ballots cannot reuse a vote for a competing authority")
	await _mesh(5)
	_drop(0)
	split = true
	_ticks(18)
	for i in range(1, 5): check(rooms[i].phase == "ended", "partitioned minorities cannot resume competing authorities")
	await _mesh(3)
	var peer := rooms[1]
	peer.receive({"type": "packet", "key": rooms[2].local_key, "data": {"kind": "br_migrate", "epoch": peer.epoch, "term": 99, "attempt": 0}})
	check(peer.phase == "playing", "wrong-term suspicion cannot pause a live match")
	var invalid := BattleCheckpoint.decode(peer.migration.checkpoint, peer.members) as Dictionary
	invalid.motors[0][2] = -1
	check(BattleCheckpoint.decode(JSON.stringify(invalid), peer.members).is_empty(), "negative movement timers are rejected")
	invalid = BattleCheckpoint.decode(peer.migration.checkpoint, peer.members)
	invalid.reloads[0] = "1"
	check(BattleCheckpoint.decode(JSON.stringify(invalid), peer.members).is_empty(), "checkpoint nested types are checked before restore")
	check(BattleCheckpoint.decode("x".repeat(BattleCheckpoint.MAX_BYTES + 1), peer.members).is_empty(), "oversized checkpoint is rejected before parsing")
	rooms[0].migration.leases.clear()
	_ticks(3.5)
	check(rooms[0].phase == "recovering", "authority freezes when its survivor lease quorum expires")
	_ticks(4)
	check(peer.phase == "playing" and peer.term == 1, "lease expiry can hand off a silent authority")
	await _mesh(4)
	_drop(2)
	_drop(3)
	var electorate := rooms[0].migration.voters.duplicate()
	rooms[0].migration.publish(_checkpoint(rooms[0], 2))
	check(rooms[0].migration.voters == electorate and rooms[0].migration.checkpoint_seq == 1, "authority cannot silently shrink its electorate after losing peers")
	_ticks(3.5)
	check(rooms[0].phase == "recovering", "minority authority freezes even if missing players could become CPUs")
	await _mesh(20)
	_drop(0)
	_ticks(4)
	for i in range(1, 20): check(rooms[i].phase == "playing" and rooms[i].host_key == rooms[1].local_key, "twenty-seat recovery agrees over JSON mesh")
	await _clear()
	print("Battle host migration: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _mesh(count: int) -> void:
	await _clear()
	blocked.clear()
	split = false
	restores.clear()
	var members: Array = []
	for i in count: members.append({"key": "%064x" % (i + 1), "name": "Bean %d" % i, "skin": i % 8})
	for i in count:
		var room := BattleRoom.new()
		room.options = [20 - count, 1]
		room.local_key = members[i].key
		room.host_key = members[0].key
		room.epoch = "a".repeat(24)
		room.members = members.duplicate(true)
		room.phase = "playing"
		for member: Dictionary in members:
			room.connected[member.key] = true
			if member.key != room.local_key: room.peers[member.key] = member.name
		room.send_packet = func(key: String, data: Dictionary) -> void: _deliver(room.local_key, key, data)
		room.migration.restoring.connect(func(state: Dictionary) -> void: restores[room.local_key] = state)
		root.add_child(room)
		room.set_process(false)
		rooms.append(room)
	rooms[0].migration.publish(_checkpoint(rooms[0], 1))
	check(rooms[-1].migration.checkpoint_seq == 1, "every guest receives a validated recovery checkpoint")

func _checkpoint(room: BattleRoom, sequence: int) -> String:
	var state := BattleMatch.new()
	var positions: Array[Vector3] = []
	for i in 20: positions.append(Vector3(i, 0, 0))
	state.initialize(positions, room.members.size(), room.options)
	state.time = 45
	state.sequence = sequence - 1
	var packet := state.capture()
	packet.cooldowns = state.cooldowns.duplicate()
	packet.reloads = state.reloads.duplicate()
	packet.cooldowns[1] = 0.42
	packet.reloads[1] = 1.3
	packet.tick = 2700
	packet.voters = []
	for i in room.members.size():
		if room.connected.has(room.members[i].key): packet.voters.append(room.members[i].key)
		else: packet.actors[i][17] = 1
	packet.motors = []
	for i in 20:
		var motor: Array = []
		motor.resize(BattleCheckpoint.MOTOR_SIZE)
		motor.fill(0)
		motor[15] = 73.0
		packet.motors.append(motor)
	return JSON.stringify(packet)

func _drop(slot: int) -> void:
	var key := rooms[slot].local_key
	blocked.append(key)
	for room: BattleRoom in rooms:
		if not blocked.has(room.local_key): room.receive({"type": "left", "key": key})

func _ticks(seconds: float) -> void:
	for tick in ceili(seconds * 20):
		for room: BattleRoom in rooms:
			if not blocked.has(room.local_key): room._process(0.05)

func _deliver(from: String, to: String, packet: Dictionary) -> void:
	if blocked.has(from) or blocked.has(to): return
	if split and ((from in [rooms[1].local_key, rooms[2].local_key]) != (to in [rooms[1].local_key, rooms[2].local_key])): return
	for room: BattleRoom in rooms:
		if room.local_key == to:
			room.receive({"type": "packet", "key": from, "data": JSON.parse_string(JSON.stringify(packet))})
			return

func _clear() -> void:
	for room: BattleRoom in rooms: room.queue_free()
	rooms.clear()
	await process_frame
