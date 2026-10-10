extends SceneTree
## Render the village plan, barn interior and both Fufu NPCs with the actual renderer.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.chat.view.hide()
	game.weather_view.hide()
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.cycle.set_process(false)
	game.cycle.phase = 0.4
	game.cycle._process(0)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	# The elevated overview must include decorations normally culled from play cameras.
	for patch: GeometryInstance3D in game.world.get_node("WildGrass").get_children():
		patch.visibility_range_end = 0
	for decoration: Node in game.world.get_node("E_FloralGarden").get_children():
		if decoration is GeometryInstance3D: decoration.visibility_range_end = 0
	var views: Array[Dictionary] = [
		{"name": "village", "at": Vector3(45, 0, -30), "camera": Vector3(45, 56, 25)},
		{"name": "barn", "at": Vector3(24, 1, -25), "camera": Vector3(24, 18, -5)},
		{"name": "grandma", "at": Vector3(46, 1, -13), "camera": Vector3(46, 5, -21)},
		{"name": "grandpa", "at": Vector3(33.5, 1, -42.5), "camera": Vector3(33.5, 5, -33.5)},
		{"name": "kitchen", "at": Vector3(52.1, 1, -54), "camera": Vector3(52.1, 7.0, -45)},
		{"name": "garden", "at": Vector3(47, 0.8, -25), "camera": Vector3(47, 19, -7)},
		{"name": "well", "at": Vector3(56.5, 1.2, -19), "camera": Vector3(60, 4.7, -14)},
		{"name": "walnuts", "at": Vector3(47.2, 0.1, -33.8), "camera": Vector3(49, 2.2, -31.0)},
		{"name": "guest", "at": Vector3(58.3, 1, -54), "camera": Vector3(58.3, 10, -43)},
	]
	for view in views:
		game.player.visible = view.name not in ["grandma", "grandpa", "well", "walnuts"]
		game.player.position = view.at + Vector3(0, 0, -3 if view.name == "grandma" else 1)
		game.camera.position = view.camera
		game.camera.look_at(view.at)
		game.camera.fov = 55
		for i in 30: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/meadow-" + view.name + ".png")
	game.queue_free()
	for i in 3: await process_frame
	quit()
