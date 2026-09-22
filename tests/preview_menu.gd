extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node = load("res://game/app/launch.tscn").instantiate()
	root.add_child(scene)
	await _capture("title")
	scene.saves.show_new()
	await _capture("new")
	scene.settings.show_settings()
	await _capture("settings")
	scene.lobby.show_lobby()
	await _capture("coop")
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
	await scene.connection.select_transport(scene.server_transport)
	scene.lobby.show_lobby()
	await _capture("dedicated")
	root.size = Vector2i(960, 540)
	scene.menu.show_home()
	await _capture("small")
	scene.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-menu-" + label + ".png")
