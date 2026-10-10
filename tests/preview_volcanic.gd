extends SceneTree
## Actual Godot captures of the continent, sea, castle cutaway and King Lava plaza.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 4: await physics_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.hud.visible = false
	game.chat.view.visible = false
	game.weather_view.visible = false
	game.cycle.world_environment.environment.fog_density = 0.00025
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.far = 1200
	print("CAMERA near/far: ", game.camera.near, "/", game.camera.far)
	game.player.global_position = game.world.volcanic.point(235, 318, 0.1)
	game.camera.position = Vector3(235, 330, 745)
	game.camera.look_at(Vector3(450, 30, 380))
	await capture("continent")
	game.camera.position = Vector3(174, 15, 346)
	game.camera.look_at(Vector3(276, 9, 306))
	await capture("ocean")
	for i in VolcanicLandmarks.SITES.size():
		var at := VolcanicTerrain.point(VolcanicLandmarks.SITES[i])
		game.player.global_position = at + Vector3.UP * 0.1
		game.camera.position = at + Vector3(22, 24, 33)
		game.camera.look_at(at + Vector3.UP * 1.5)
		await capture("district_" + str(i))
	game.player.global_position = VolcanicTerrain.point(Vector2(430, 265), 0.1)
	game.camera.position = Vector3(340, 78, 238)
	game.camera.look_at(Vector3(450, 71, 380))
	await capture("volcano")
	var crater := VolcanicTerrain.point(VolcanicTerrain.VOLCANO)
	game.camera.position = crater + Vector3(28, 52, 32)
	game.camera.look_at(crater)
	await capture("crater")
	game.camera.position = Vector3(379, 78, 423)
	game.camera.look_at(Vector3(316, 20, 334))
	await capture("castle")
	game.player.global_position = game.world.volcanic.castle.to_global(Vector3(0, 0.1, 24))
	game.camera.position = game.player.position + Vector3(17, 37, 26)
	game.camera.look_at(game.player.position + Vector3(0, 0, -13))
	await capture("maze")
	var king := game.world.volcanic.castle.king
	game.player.global_position = king.global_position + Vector3(0, 0.1, -5)
	game.camera.position = king.global_position + Vector3(7, 5, 13)
	game.camera.look_at(king.global_position + Vector3.UP * 2.3)
	await capture("king")
	game.queue_free()
	for frame in 5: await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 25: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-volcanic-" + label + ".png")
