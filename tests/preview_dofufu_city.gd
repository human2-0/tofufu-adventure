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
	for spec in [Vector4(-860, 0, 24, 34), Vector4(-923, 0, 13, 22), Vector4(-935, 0, 4, 8), Vector4(-485, DofufuTerrain.trail_z(-485), 18, 22)]:
		var center := terrain.point(spec.x, spec.y, 1)
		game.player.position = center + Vector3(0, 0, 4)
		game.camera.position = center + Vector3(spec.w * 0.5, spec.z, spec.w)
		game.camera.look_at(center)
		for i in 10: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/dofufu-view-%d.png" % int(-spec.x))
	# Check the actual overhead boom in the steepest early switchbacks.
	game.player.position = terrain.trail_point(-248) + Vector3.UP * 0.1
	for direction in 4:
		game.camera._overhead_yaw = -direction * PI * 0.5
		game.camera.reset_follow()
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/dofufu-overhead-%d.png" % direction)
	var master := game.world.dofufu_highlands.city.residents["Dofufu Master"]
	master.view_focus = null
	master.art.facing = Vector2.RIGHT
	for index in 5:
		var angle := index * PI / 4
		game.camera.position = master.position + Vector3(cos(angle) * 6, 2.8, sin(angle) * 6)
		game.camera.look_at(master.position + Vector3.UP)
		for i in 5: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/dofufu-angle-%d.png" % index)
	game.queue_free()
	await process_frame
	quit()
