extends SceneTree
## Beach, reflective swells, playable seabed and underwater camera views.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 3: await physics_frame
	game.hud.visible = false
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.weather.set_phase(0.0)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.player.set_physics_process(false)
	game.camera.fov = 60
	game.player.position = game.world.ground_point(0, -96, 0.1)
	game.camera.position = Vector3(22, 13, -80)
	game.camera.look_at(Vector3(0, 1, -111))
	await capture("beach")
	game.camera.position = Vector3(30, 4, -111)
	game.camera.look_at(Vector3(5, 1.8, -161))
	await capture("waves")
	game.player.position = game.world.ground_point(0, -137, 0.1)
	game.camera.fov = 48
	game.camera.position = game.player.position + game.camera.offset
	game.camera._update_camera_orientation()
	await capture("gameplay")
	game.camera.fov = 65
	game.camera.position = Vector3(0, -1.3, -125)
	game.camera.look_at(Vector3(0, -2.1, -144))
	await capture("underwater")
	game.camera.position = game.player.position + Vector3(4.5, 2.3, 5)
	game.camera.look_at(game.player.position + Vector3.UP * 1.2)
	var experience := game.get_node("WorldLife/OceanExperience") as OceanExperience
	experience.bubbles.breathe(game.player.position, Vector2.DOWN)
	await capture("breath")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 45: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-ocean-" + label + ".png")
