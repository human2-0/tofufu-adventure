extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.weather.set_physics_process(false)
	game.cycle.phase = 0.18
	game.cycle.set_process(false)
	game.cycle._process(0)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	var archer := game.encounters.mob_nodes[43] as TofufuArcher
	game.player.position = game.world.ground_point(-31, 378, 0.1)
	var center := game.world.ground_point(-30, 375, 1)
	game.camera.position = center + Vector3(0, 10, 18)
	game.camera.look_at(center)
	archer.quarry = game.player
	archer._choose_direction(0.01)
	archer.facing = Vector3(archer._sting_aim.x, 0, archer._sting_aim.z).normalized()
	for i in 25: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-groatfields.png")
	archer._choose_direction(0.91)
	archer.sting.step(0.16, archer.protected_area, archer.get_rid())
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-groat-flight.png")
	game.hud.show()
	game.player.position = game.world.cloud_realm.godfufu.position + Vector3(0, 0, 2)
	game.camera.position = game.player.position + Vector3(0, 8, 12)
	game.camera.look_at(game.player.position + Vector3.UP)
	game.god_hunt.window.visible = true
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-god-hunt.png")
	game.queue_free()
	await process_frame
	quit()
