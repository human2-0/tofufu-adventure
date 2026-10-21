extends SceneTree
## Render the real city, accessible rooftops and its connection to Embercrown.

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 1000)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 4: await physics_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.42
	game.cycle._process(0)
	game.hud.visible = false
	game.chat.view.visible = false
	game.weather_view.visible = false
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.far = 1500
	game.cycle.world_environment.environment.fog_enabled = false
	var views: Array[Dictionary] = [
		{"id": "east-overview", "eye": Vector3(800, 450, -370), "aim": Vector3(350, 5, 155), "actor": Vector3(420, 6.1, 6)},
		{"id": "east-market", "eye": Vector3(327, 24, 94), "aim": Vector3(292, 5, 50), "actor": Vector3(292, 3.1, 68)},
		{"id": "east-warehouse", "eye": Vector3(390, 28, 87), "aim": Vector3(356, 10, 50), "actor": Vector3(376, 6.1, 69)},
		{"id": "east-hall", "eye": Vector3(457, 32, 91), "aim": Vector3(420, 13, 45), "actor": Vector3(424, 6.1, 48)},
		{"id": "east-clock", "eye": Vector3(580, 49, 185), "aim": Vector3(548, 23, 132), "actor": Vector3(555, 32.1, 127)},
		{"id": "east-homes", "eye": Vector3(442, 22, 16), "aim": Vector3(420, 10, -24), "actor": Vector3(420, 6.1, -5)},
		{"id": "overview", "eye": Vector3(440, 320, 440), "aim": Vector3(175, 2, 155), "actor": Vector3(160, 4.1, 110)},
		{"id": "old-town", "eye": Vector3(212, 53, 75), "aim": Vector3(154, 3, 8), "actor": Vector3(134, 0.1, 6)},
		{"id": "streets", "eye": Vector3(173, 18, 112), "aim": Vector3(156, 7, 154), "actor": Vector3(160, 4.1, 114)},
		{"id": "camp", "eye": Vector3(144, 27, 148), "aim": Vector3(122, 12, 126), "actor": Vector3(128, 12.1, 126)},
		{"id": "coast", "eye": Vector3(108, 120, 267), "aim": Vector3(242, 2, 315), "actor": Vector3(208, 3.7, 318)},
		{"id": "watch", "eye": Vector3(184, 27, 398), "aim": Vector3(325, 33, 369), "actor": Vector3(213, 15.7, 374)}
	]
	for view in views:
		game.player.relocate(view.actor)
		game.camera.position = view.eye
		game.camera.look_at(view.aim)
		for frame in 20: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-gigalopolis-" + view.id + ".png")
	game.queue_free()
	for frame in 5: await process_frame
	quit()
