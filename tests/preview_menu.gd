extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	var fake = preload("res://tests/lobby_test_transport.gd").inject(scene)
	fake.announce_ready = false
	scene.preferences.path = "user://preview-coop-%d.cfg" % Time.get_ticks_usec()
	root.add_child(scene)
	await _capture("title")
	scene.saves.show_new()
	await _capture("new")
	scene.settings.show_settings()
	await _capture("settings")
	scene.preferences.nickname = "Miso Bean"
	scene.lobby.show_lobby()
	await _capture("coop-starting")
	fake.event_received.emit({"type": "ready", "key": fake.key, "name": fake.nickname})
	await _capture("coop")
	scene.lobby.panel.identity._open()
	await _capture("coop-nickname")
	scene.lobby.panel.identity._close()
	scene.room.local_key = "a".repeat(64)
	scene.room.create_room()
	await _capture("coop-host")
	scene.room.leave()
	var friend := "b".repeat(64)
	scene.room.receive({"type": "peer", "key": friend, "name": "Friend"})
	scene.room.receive({"type": "packet", "key": friend, "data": {"type": "presence", "hosting": true, "busy": true}})
	scene.room.join_room(friend)
	await _capture("coop-joining")
	scene.room.receive({"type": "left", "key": friend})
	await _capture("coop-reconnecting")
	fake.event_received.emit({"type": "error", "message": "Could not connect to friends. Check your connection, then retry."})
	await _capture("coop-error")
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	scene.lobby.show_lobby()
	await _capture("coop-compact")
	fake.announce_ready = true
	scene.lobby.panel.discover.emit(scene.preferences.nickname)
	await _capture("coop-compact-ready")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await scene.connection.select_transport(scene.server_transport)
	scene.lobby.show_lobby()
	await _capture("dedicated")
	root.size = Vector2i(960, 540)
	scene.menu.show_home()
	await _capture("small")
	DirAccess.remove_absolute(scene.preferences.path)
	scene.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-menu-" + label + ".png")
