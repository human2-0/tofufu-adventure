extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	var host_key := "a".repeat(64)
	var guest_key := "b".repeat(64)
	host.local_key = host_key
	guest.local_key = guest_key
	host.peers[guest_key] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[host_key] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": host_key, "data": data})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": guest_key, "data": data})
	host.create_room()
	guest.join_room(host_key)
	assert(host.members.size() == 2 and guest.members.size() == 2)
	host.begin()
	assert(host.playing and guest.playing)
	var sessions: Array[CoopSession] = []
	for room in [host, guest]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		root.add_child(viewport)
		var game: Node3D = load("res://game/app/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		var session := CoopSession.new()
		session.game = game
		session.room = room
		game.add_child(session)
		sessions.append(session)
	for frame in 10: await physics_frame
	assert(sessions[0].roster.actors.size() == 2 and sessions[1].roster.actors.size() == 2)
	assert(sessions[1]._synchronized, "guest receives host snapshots")
	assert(sessions[0]._window._last.has(guest_key), "host receives guest commands")
	var host_chat: ProximityChat = sessions[0].game.chat
	var guest_chat: ProximityChat = sessions[1].game.chat
	host_chat._submit("Hello from the host", false)
	assert(guest_chat.view.history[-1] == "Host: Hello from the host")
	guest_chat._submit("Hello from the guest", false)
	assert(host_chat.view.history[-1] == "Guest: Hello from the guest")
	assert(guest_chat.view.history[-1] == "You: Hello from the guest")
	var count := guest_chat.view.history.size()
	guest_chat._packet(guest_key, {"type": "chat_text", "sequence": 99, "sender": host_key, "text": "Forged", "yell": true})
	assert(guest_chat.view.history.size() == count, "guest accepts deliveries only from host")
	host.leave()
	assert(not guest.playing, "host loss ends guest session")
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Co-op scene: PASS")
	quit()
