extends SceneTree
## Real loopback sockets, authenticated admission, server-owned world and reconnect.

var server: DedicatedServer
var clients: Array[OracleTransport] = []
var rooms: Array[PlaytestRoom] = []
var guest_session: CoopSession
var state_dir := "user://oracle-test-%d" % Time.get_ticks_usec()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_capacity()
	var timer := create_timer(25)
	timer.timeout.connect(func() -> void:
		push_error("Oracle test timed out")
		quit(1))
	var transport := OracleTransport.new()
	transport.server_mode = true
	transport.port = 0
	transport.credentials = {"server_id": "f".repeat(64), "players": ["a".repeat(64).sha256_text(), "b".repeat(64).sha256_text()]}
	server = DedicatedServer.new()
	server.state_directory = state_dir
	server.transport = transport
	server.add_child(transport)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	viewport.add_child(server)
	assert(server.room.playing and server.room.members.is_empty())
	assert(server.session.roster.party.is_empty(), "server must not consume a player slot")
	assert(server.game.player.collision_layer == 0 and server.game.exploration.explorer == null)
	var port := transport._listener.get_local_port()
	for token: String in ["a", "b"]:
		var client := OracleTransport.new()
		client.credentials = {"endpoint": "ws://127.0.0.1:%d" % port, "token": token.repeat(64)}
		var room := PlaytestRoom.new()
		root.add_child(room)
		root.add_child(client)
		room.send_packet = client.send_packet
		client.event_received.connect(room.receive)
		clients.append(client)
		rooms.append(room)
		client.start("Guest " + token)
	while rooms[0].peers.is_empty() or rooms[1].peers.is_empty(): await process_frame
	for room: PlaytestRoom in rooms: room.join_room(server.room.local_key)
	while not rooms[0].playing or not rooms[1].playing: await process_frame
	assert(server.room.members.size() == 2 and server.room.local_key not in server.room.members)
	assert(rooms[0].dedicated and server.room.local_key not in rooms[0].members)
	var guest_view := SubViewport.new()
	guest_view.own_world_3d = true
	root.add_child(guest_view)
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	guest_view.add_child(game)
	guest_session = CoopSession.new()
	guest_session.game = game
	guest_session.room = rooms[0]
	game.add_child(guest_session)
	while not guest_session._synchronized: await physics_frame
	assert(guest_session.roster.party.size() == 2)
	for frame in 20: await physics_frame
	assert(server.session._window._last.has(rooms[0].local_key), "authenticated guest commands reach simulation")
	var identity := rooms[0].local_key
	server.session.roster.party[identity].progression.progress.award_experience(123)
	# Duplicate credential and an unknown credential cannot take over a connection.
	for token: String in ["a", "c"]:
		var bad := OracleTransport.new()
		bad.credentials = {"endpoint": "ws://127.0.0.1:%d" % port, "token": token.repeat(64)}
		root.add_child(bad)
		bad.start("Intruder")
		while not bad.is_closed(): await process_frame
		bad.queue_free()
	assert(server.room.members.size() == 2)
	var identities: Array[String] = []
	transport.event_received.connect(func(event: Dictionary) -> void:
		if event.get("type") == "packet" and event.data.get("type") == "oracle_test": identities.append(event.key))
	clients[0].send_packet(server.room.local_key, {"type": "oracle_test", "key": "e".repeat(64)})
	while identities.is_empty(): await process_frame
	assert(identities[0] == identity, "payload cannot forge the transport identity")
	rooms[0].leave()
	while identity in server.room.members: await process_frame
	assert(not clients[0].is_closed(), "leaving removes the avatar without closing discovery")
	clients[0].close()
	assert(server.save_world())
	assert(server.store.read_slot(0).coop.party[identity].progression.experience == 123)
	rooms[0].leave()
	rooms[0].clear_discovery()
	clients[0].start("Guest a")
	while rooms[0].peers.is_empty(): await process_frame
	rooms[0].join_room(server.room.local_key)
	while not rooms[0].playing: await process_frame
	assert(server.session.roster.party[identity].progression.progress.experience == 123)
	clients[1]._links[0].socket.put_packet("not JSON".to_utf8_buffer())
	while not clients[1].is_closed(): await process_frame
	assert(identity in server.room.members, "malformed peer does not disconnect a healthy player")
	for client: OracleTransport in clients: client.close()
	while not server.room.members.is_empty(): await process_frame
	assert(server.room.playing and server.save_world(), "empty world keeps running and saving")
	transport.close()
	var checkpoint := server.store.read_slot(0)
	assert(checkpoint.coop.party.size() == 2)
	var credentials := transport.credentials.duplicate(true)
	viewport.queue_free()
	await process_frame
	var restarted_transport := OracleTransport.new()
	restarted_transport.server_mode = true
	restarted_transport.port = 0
	restarted_transport.credentials = credentials
	server = DedicatedServer.new()
	server.state_directory = state_dir
	server.transport = restarted_transport
	server.add_child(restarted_transport)
	var restarted_view := SubViewport.new()
	restarted_view.own_world_3d = true
	root.add_child(restarted_view)
	restarted_view.add_child(server)
	assert(server.room.playing and server.session.roster.party.is_empty())
	assert(server.session.roster.saved_states[identity].progression.experience == 123, "full server restart restores character progress")
	assert(server.store.remove_slot(0))
	DirAccess.remove_absolute(state_dir)
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Oracle dedicated sockets, identity, replication and persistence: PASS")
	quit()

func _test_capacity() -> void:
	var room := PlaytestRoom.new()
	root.add_child(room)
	room.dedicated = true
	room.local_key = "f".repeat(64)
	var sent: Array[Dictionary] = []
	room.send_packet = func(key: String, packet: Dictionary) -> void: sent.append({"key": key, "packet": packet})
	room.create_room()
	room.begin()
	for letter: String in ["a", "b", "c", "d", "e"]:
		var key := letter.repeat(64)
		room.receive({"type": "peer", "key": key, "name": letter})
		room.receive({"type": "packet", "key": key, "data": {"type": "join", "version": PlaytestRoom.GAME_VERSION}})
	assert(room.members.size() == 4 and room.local_key not in room.members)
	assert(sent[-1].key == "e".repeat(64) and sent[-1].packet.type == "reject")
	room.queue_free()
