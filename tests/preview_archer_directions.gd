extends SceneTree
## Native check of all eight travel views, both strides, attack pose and camera orbit.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.chat.view.hide()
	game.player.set_physics_process(false)
	game.player.hide()
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.weather.set_physics_process(false)
	game.cycle.phase = 0.45
	game.cycle.set_process(false)
	game.cycle._process(0)
	for mob in game.encounters.mob_nodes:
		mob.set_physics_process(false)
		mob.hide()
	var center := game.world.ground_point(0, 375, 1.4)
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.size = 23.0
	game.camera.position = center + Vector3(0, 13, 20)
	game.camera.look_at(center)
	var forward := game.camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	for index in 8:
		var archer := game.encounters.mob_nodes[43 + index] as TofufuArcher
		archer.show()
		archer.set_process(false)
		archer._nameplate.text = ["S", "SW", "W", "NW", "N", "NE", "E", "SE"][index]
		archer.position = game.world.ground_point((index % 4 - 1.5) * 5, 371 + (index / 4) * 8, 0.1)
		archer.facing = forward * cos(index * PI / 4) - right * sin(index * PI / 4)
		archer.art.elapsed = 0.01
		archer.art.present(archer.facing, 0, 0, true)
	await capture("walk-a")
	for index in 8:
		var archer := game.encounters.mob_nodes[43 + index] as TofufuArcher
		archer.art.present(archer.facing, 0, 0.18, true)
	await capture("walk-b")
	game.camera.position = center + Vector3(20, 13, 0)
	game.camera.look_at(center)
	for index in 8:
		var archer := game.encounters.mob_nodes[43 + index] as TofufuArcher
		archer.art.present(archer.facing, 0, 0, true)
	await capture("orbit")
	TranslationServer.set_locale("pl")
	await capture("polish")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-archer-" + label + ".png")
