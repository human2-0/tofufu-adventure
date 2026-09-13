extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	host.local_key = "a".repeat(64)
	guest.local_key = "b".repeat(64)
	host.peers[guest.local_key] = {"name": "Mame", "hosting": false, "busy": false}
	guest.peers[host.local_key] = {"name": "Fufu", "hosting": true, "busy": false}
	host.local_name = "Fufu"
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": host.local_key, "data": JSON.parse_string(JSON.stringify(data))})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": guest.local_key, "data": JSON.parse_string(JSON.stringify(data))})
	host.create_room()
	guest.join_room(host.local_key)
	host.begin()
	var views: Array[SubViewport] = []
	var sessions: Array[CoopSession] = []
	for room in [host, guest]:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = Vector2i(1280, 720)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var game: Node3D = load("res://game/app/main.tscn").instantiate()
		game.play_opening = false
		viewport.add_child(game)
		game.hud.toggle_help()
		var session := CoopSession.new()
		session.game = game
		session.room = room
		game.add_child(session)
		views.append(viewport)
		sessions.append(session)
	var input := CoopTestInput.new()
	root.add_child(input)
	input.guard = true
	sessions[1].roster.local_input = input
	(sessions[0].roster.local_input as LocalPlayerInput).enabled = false
	sessions[0].roster.actors[host.local_key].position = Vector3(-7, 0.1, 0)
	sessions[0].roster.actors[guest.local_key].position = Vector3(-9, 0.1, -1)
	for frame in 120: await process_frame
	await RenderingServer.frame_post_draw
	for index in views.size():
		views[index].get_texture().get_image().save_png("/tmp/tofufu-coop-%s.png" % ("host" if index == 0 else "guest"))
	for child in root.get_children(): child.queue_free()
	await process_frame
	quit()
