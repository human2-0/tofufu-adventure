extends SceneTree
## A non-Holepunch implementation exercises the real room and launch boundaries.

class LocalTransport extends SessionTransport:
	var key: String
	var remote: LocalTransport
	var active: bool = false
	var starts: int = 0
	var retiring_frames: int = 0

	func start(_display_name: String) -> void:
		starts += 1
		active = true
		event_received.emit({"type": "ready", "key": key, "name": "Local tester"})
		if remote != null and remote.active:
			remote.event_received.emit({"type": "peer", "key": key, "name": "Local tester"})
			event_received.emit({"type": "peer", "key": remote.key, "name": "Local tester"})

	func send_packet(target: String, data: Dictionary) -> void:
		if active and remote != null and remote.active and target == remote.key:
			remote.event_received.emit({"type": "packet", "key": key, "data": data.duplicate(true)})

	func close() -> void:
		if not active: return
		active = false
		retiring_frames = 2
		if remote != null and remote.active:
			remote.event_received.emit({"type": "left", "key": key})

	func is_closed() -> bool:
		return not active and retiring_frames == 0

	func _process(_delta: float) -> void:
		retiring_frames = maxi(0, retiring_frames - 1)

var failures: int = 0
var deliveries: Array[Dictionary] = []

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := LocalTransport.new()
	var guest := LocalTransport.new()
	host.key = "a".repeat(64)
	guest.key = "b".repeat(64)
	host.remote = guest
	guest.remote = host
	var host_room := PlaytestRoom.new()
	var guest_room := PlaytestRoom.new()
	var host_connection := connect_room(host, host_room)
	var guest_connection := connect_room(guest, guest_room)
	host_connection.discover("Host")
	guest_connection.discover("Guest")
	host_room.create_room()
	host_room.begin()
	check(host_room.playing and host_room.members == [host.key], "host explores alone while remaining discoverable")
	guest_room.join_room(host.key)
	check(guest_room.host_key == host.key and host_room.members.size() == 2, "alternate backend supports discovery and admission")
	host_room.begin()
	check(host_room.playing and guest_room.playing, "alternate backend starts both rooms")
	host_room.gameplay_packet.connect(func(key: String, data: Dictionary) -> void:
		deliveries.append({"key": key, "data": data}))
	guest_room.send_game(host.key, {"type": "ping"})
	check(deliveries.size() == 1 and deliveries[0].key == guest.key, "authenticated sender and gameplay packet reach room")
	guest_connection.disconnect_session()
	check(host_room.members.size() == 1, "disconnect removes guest from authority roster")
	check(guest_room.local_key.is_empty() and guest_room.peers.is_empty() and guest_room.names.is_empty(), "disconnect clears discovery and names")
	guest_connection.discover("Guest")
	guest_room.join_room(host.key)
	check(guest_room.playing and guest_room.local_key == guest.key, "restart rejoins a running room with stable identity")
	host.close()
	check(not guest_room.playing and guest_room.host_key.is_empty(), "backend host loss ends guest session")
	guest.close()
	guest.event_received.emit({"type": "error", "message": "Service unavailable"})
	check(guest_room.local_key.is_empty() and guest_room.status == "Service unavailable", "backend failure resets room and reports reason")
	await guest_connection.shutdown()
	check(guest.is_closed(), "shutdown waits for backend resource retirement")
	host_connection.free()
	guest_connection.free()
	host_room.free()
	guest_room.free()
	host.remote = null
	guest.remote = null
	host.free()
	guest.free()
	check_join_recovery()
	await check_launch_injection()
	print("Session transport: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func connect_room(transport: SessionTransport, room: PlaytestRoom) -> SessionConnection:
	root.add_child(transport)
	root.add_child(room)
	var connection := SessionConnection.new()
	connection.transport = transport
	connection.room = room
	root.add_child(connection)
	return connection

func check_launch_injection() -> void:
	var app: Node = load("res://game/app/launch.tscn").instantiate()
	app.get_node("Transport").free()
	var alternate := LocalTransport.new()
	alternate.key = "c".repeat(64)
	app.add_child(alternate)
	app.transport = alternate
	app.preferences.path = "user://transport-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(app)
	check(alternate.starts == 0, "injected backend stays stopped during offline startup")
	app.lobby.show_lobby()
	check(alternate.starts == 0, "opening lobby does not start backend")
	check(app.lobby.panel.discovery_description == alternate.discovery_description(), "lobby receives backend description through contract")
	app.lobby.panel.discover.emit("Tester")
	check(alternate.starts == 1 and app.room.local_key == alternate.key, "launch discovers using injected backend")
	app.lobby.panel.back.emit()
	check(app.room.local_key.is_empty() and not alternate.active, "back to title closes injected backend")
	await app.connection.shutdown()
	check(alternate.is_closed(), "launch lifecycle supports asynchronous backend shutdown")
	app.free()

func check_join_recovery() -> void:
	var room := PlaytestRoom.new()
	var host_key := "a".repeat(64)
	var sent: Array[Dictionary] = []
	room.local_key = "b".repeat(64)
	room.send_packet = func(key: String, data: Dictionary) -> void: sent.append({"key": key, "data": data})
	room.receive({"type": "peer", "key": host_key, "name": "Friend"})
	room.receive({"type": "packet", "key": host_key, "data": {"type": "presence", "hosting": true}})
	room.join_room(host_key)
	room.receive({"type": "left", "key": host_key})
	check(room.pending_host() == host_key and room.status.contains("interrupted"), "lost join retains target and explains reconnect")
	room._process(2)
	var before := sent.size()
	room.receive({"type": "peer", "key": host_key, "name": "Friend"})
	room.receive({"type": "packet", "key": host_key, "data": {"type": "presence", "hosting": true}})
	room._process(2)
	check(sent.size() == before + 2 and sent.back().data.type == "join", "rediscovered host is retried automatically")
	room.receive({"type": "packet", "key": host_key, "data": {"type": "welcome", "members": [host_key, room.local_key], "names": {}, "epoch": "a".repeat(32), "playing": true}})
	check(room.playing and room.pending_host().is_empty(), "retry admits guest into running meadow")
	room.receive({"type": "left", "key": host_key})
	check(not room.playing and room.pending_host() == host_key, "unexpected host loss starts bounded rejoin")
	room._process(21)
	check(room.pending_host().is_empty() and room.status.contains("Could not reach"), "unreachable host ends retry with explanation")
	room.receive({"type": "peer", "key": host_key, "name": "Friend"})
	room.join_room(host_key)
	room.leave()
	before = sent.size()
	room._process(2)
	check(room.pending_host().is_empty() and sent.size() == before, "cancel joining prevents another join request")
	room.free()
