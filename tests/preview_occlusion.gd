extends SceneTree
## Render paired culling-off/on captures at walls, openings, cutaways and below clouds.
var game: AdventureGame

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.gui_disable_input = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 60
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_phase(0.05)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	var cases: Array[Dictionary] = [
		{"name": "village_first", "at": Vector3(33, 0.1, -22), "mode": 2},
		{"name": "castle_behind", "at": Vector3(316, 4.5, 355), "mode": 1},
		{"name": "castle_first", "at": Vector3(316, 4.5, 355), "mode": 2},
		{"name": "castle_cutaway", "at": Vector3(316, 4.5, 355), "mode": 0},
		{"name": "cloud_first", "at": CloudTerrain.point(-40, 314, 0.1), "mode": 2},
		{"name": "below_clouds", "at": Vector3(-40, 12, 314), "mode": 2},
		{"name": "barn_inside", "at": game.world.seed_bank.global_position + Vector3(0, 0.51, 7), "mode": 0}]
	for case in cases:
		game.player.relocate(case.at)
		while (2 if game.shooting_view.first_person else (1 if game.shooting_view.shoulder else 0)) != case.mode:
			game.shooting_view.cycle_mode()
		game.camera.yaw = 0.0
		game.camera.pitch = -1.1 if case.name == "below_clouds" else 0.12
		game.camera.reset_follow()
		game.camera._follow(1.0)
		game.world.volcanic.castle.present(game.player.position, case.mode == 0)
		for node in game.get_children():
			if node is MeadowInteriorView: node._process(0)
		var cloud_cover := game.world.cloud_realm.get_node("WalkableClouds/GroundOcclusion") as GroundOcclusion
		cloud_cover.present(game.camera.global_position)
		for enabled in [false, true]:
			root.use_occlusion_culling = enabled
			for frame in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-occlusion-%s-%s.png" % [case.name, "on" if enabled else "off"])
	game.queue_free()
	await process_frame
	await process_frame
	print("Occlusion paired captures: complete")
	quit()
