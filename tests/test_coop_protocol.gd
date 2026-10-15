extends SceneTree

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	command.attack_held = true
	var packet := CoopValues.input(command, 1, 100)
	command.reload_pressed = true
	command.reload_held = true
	var reload_packet := CoopValues.input(command, 1, 100)
	check(ExplorationProtocol.valid_input(reload_packet) and CoopValues.command(reload_packet).reload_pressed, "reload survives validated co-op input conversion")
	reload_packet.reload_pressed = 1
	check(not ExplorationProtocol.valid_input(reload_packet), "numeric reload intent is rejected")
	var window := InputWindow.new()
	check(window.accept("peer", packet, 100), "valid fresh intent accepted")
	check(not window.accept("peer", packet, 100), "replayed sequence rejected")
	packet.sequence = 2
	check(not window.accept("peer", packet, 281), "old snapshot acknowledgement rejected")
	packet.ack = 1000
	check(not window.accept("peer", packet, 100), "future acknowledgement rejected")
	packet.ack = 100
	packet.move = [9, 0]
	check(not window.accept("peer", packet, 100), "overspeed vector rejected")
	packet.move = [0, 0]
	packet.attack_held = 1
	check(not window.accept("peer", packet, 100), "numeric bool rejected")
	packet.attack_held = true
	for sequence in range(2, 91):
		packet.sequence = sequence
		window.accept("peer", packet, 100)
	packet.sequence = 91
	check(not window.accept("peer", packet, 100), "command flood is bounded")
	check(not ExplorationProtocol.key("x".repeat(64)), "invalid identity key rejected without decoding")
	var remote := RemotePlayerInput.new()
	command.jump_pressed = true
	remote.accept(command)
	check(remote.sample(Vector3.ZERO).jump_pressed, "edge consumed first time")
	check(not remote.sample(Vector3.ZERO).jump_pressed, "edge never replayed while holding")
	var reload_command := PlayerCommand.new()
	reload_command.reload_pressed = true
	reload_command.reload_held = true
	remote.accept(reload_command)
	var newest := PlayerCommand.new()
	newest.reload_held = true
	remote.accept(newest)
	check(remote.sample(Vector3.ZERO).reload_pressed, "queued reload edge survives coalescing")
	var held_reload := remote.sample(Vector3.ZERO)
	check(held_reload.reload_held and not held_reload.reload_pressed, "remote reload edge is consumed once while Square stays held")
	remote._last_received = Time.get_ticks_msec() - 300
	var stopped := remote.sample(Vector3.ZERO)
	check(stopped.move.is_zero_approx() and not stopped.attack_held and stopped.cancel_actions, "silent guest cancels holds without releasing an attack")
	for i in 50: remote.accept(PlayerCommand.new())
	check(remote.pending.size() <= 12, "remote input queue bounded")
	var recovered := remote.sample(Vector3.ZERO)
	check(recovered.cancel_actions and not recovered.jump_pressed and remote.pending.is_empty(), "overflow discards stale actions and recovers without kicking")
	for tick in 60:
		for arrival in 3:
			var latest := PlayerCommand.new()
			latest.move = Vector2.RIGHT if arrival < 2 else Vector2.LEFT
			latest.dash_pressed = arrival == 0
			check(remote.accept(latest), "slower host accepts faster guest input")
		var sampled := remote.sample(Vector3.ZERO)
		check(sampled.move == Vector2.LEFT and sampled.dash_pressed, "latest intent wins and queued edge is delivered once")
		check(remote.pending.is_empty(), "each host tick drains incoming intent")
	check(not remote.sample(Vector3.ZERO).dash_pressed, "coalesced edge is never repeated")
	remote.free()
	var room := PlaytestRoom.new()
	room.local_key = "a".repeat(64)
	room.send_packet = func(_key: String, _data: Dictionary) -> void: pass
	room.create_room()
	var old_peer := "f".repeat(64)
	room.peers[old_peer] = {"name": "Old build", "hosting": false, "busy": false}
	room.receive({"type": "packet", "key": old_peer, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION - 1}})
	check(old_peer not in room.members, "older clients without cloud terrain cannot join the new world")
	for letter: String in ["b", "c", "d", "e"]:
		var key := letter.repeat(64)
		room.peers[key] = {"name": letter, "hosting": false, "busy": false}
		room.receive({"type": "packet", "key": key, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION}})
	check(room.members.size() == 4 and "e".repeat(64) not in room.members, "host enforces four-player capacity")
	room.free()
	print("Co-op protocol: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
