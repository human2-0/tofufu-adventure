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
	game.cycle.phase = 0.45
	game.cycle.set_process(false)
	game.cycle._process(0)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	var terrain := game.world.dofufu_highlands.terrain
	for spec in [Vector4(-574, 125, 12, 18), Vector4(-510, 70, 9, 14), Vector4(-774, -136, 10, 17), Vector4(-485, DofufuTerrain.trail_z(-485), 14, 20)]:
		var at := terrain.point(spec.x, spec.y)
		game.player.position = at
		game.camera.position = at + Vector3(7, spec.z, spec.w)
		game.camera.look_at(at)
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/mountain-retreat-%d.png" % int(-spec.x))
	for at2 in [Vector2(-535, 101), Vector2(-720, -105)]:
		game.player.position = terrain.point(at2.x, at2.y, 0.1)
		for direction in 4:
			game.camera._overhead_yaw = -direction * PI / 2
			game.camera.reset_follow()
			for frame in 5: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/mountain-overhead-%d-%d.png" % [int(-at2.x), direction])
	game.player.position = terrain.point(-574, 121.5, 0.1)
	game.camera._overhead_yaw = 0
	game.camera.reset_follow()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/mountain-hut-inside.png")
	var hermit := game.world.dofufu_highlands.retreat.hermit
	hermit.view_focus = null
	hermit.art.facing = Vector2.RIGHT
	for direction in 5:
		var angle := direction * PI / 4
		game.camera.position = hermit.position + Vector3(cos(angle) * 5, 2.4, sin(angle) * 5)
		game.camera.look_at(hermit.position + Vector3.UP * 1.1)
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/mountain-hybrid-%d.png" % direction)
	game.queue_free()
	await process_frame
	quit()
