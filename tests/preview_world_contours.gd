extends SceneTree
## Atoll overview, lagoon walking, soft biome crossings and actual terrain cartography.

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 3: await physics_frame
	game.hud.visible = false
	game.weather_view.visible = false
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.weather.set_phase(0)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.camera.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position = game.world.ocean.point(80, -169, 0.1)
	game.camera.fov = 62
	game.camera.position = Vector3(109, 43, -102)
	game.camera.look_at(Vector3(66, 1.8, -157))
	await capture("atoll")
	game.camera.position = Vector3(76, 10, -137)
	game.camera.look_at(Vector3(65, 1.6, -160))
	await capture("lagoon")
	game.player.position = game.world.ground_point(24, 94, 0.1)
	game.camera.position = Vector3(49, 22, 54)
	game.camera.look_at(Vector3(15, 1.2, 101))
	await capture("meadow-dunes")
	game.player.position = game.world.ground_point(24, 220, 0.1)
	game.camera.position = Vector3(47, 22, 185)
	game.camera.look_at(Vector3(10, 1.8, 230))
	await capture("dunes-jungle")
	game.map.view.full.terrain_texture.get_image().save_png("/tmp/tofufu-world-terrain-map.png")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 25: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-world-" + label + ".png")
