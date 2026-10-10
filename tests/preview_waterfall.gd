extends SceneTree
## Sunny sanctuary, wildlife detail, rain and the recovering rainbow sky.

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
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle.sky_effects.tropical_blend = 1.0
	game.cycle._process(0)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.fov = 65
	var falls := game.world.jungle.waterfall
	game.player.relocate(falls.to_global(Vector3(0, 0.1, -12)))
	game.player.set_physics_process(false)
	game.camera.position = falls.to_global(Vector3(20, 10, -27))
	game.camera.look_at(falls.to_global(Vector3(0, 4, 3)))
	await capture("sunny")
	game.camera.position = falls.to_global(Vector3(-14, 3, -1))
	game.camera.look_at(falls.to_global(Vector3(-8, 0.5, 4)))
	await capture("wildlife")
	game.player.relocate(falls.to_global(Vector3(0, 0.1, -2)))
	game.camera.fov = 48
	game.camera.position = game.player.position + game.camera.offset
	game.camera._update_camera_orientation()
	await capture("gameplay")
	game.camera.fov = 65
	game.camera.position = falls.to_global(Vector3(10, 4, -21))
	game.camera.look_at(falls.to_global(Vector3(0, 5, 5)))
	game.weather.set_phase(0.45)
	game.cycle._clouds = 1.0
	game.cycle._process(0)
	await capture("rain")
	game.weather.set_phase(0.80)
	game.cycle._clouds = 0.0
	game.cycle._process(0)
	var sun: Vector3 = game.cycle.sky_effects.material.get_shader_parameter("sun_direction")
	game.camera.position = falls.global_position + Vector3(0, 3, -10)
	game.camera.look_at(game.camera.position + Vector3(-sun.x, 0.24, -sun.z))
	await capture("rainbow")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 60: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-waterfall-" + label + ".png")
