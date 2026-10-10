extends SceneTree
## Native 1440p rear-view ablations; never infer performance from headless runs.
var viewport: SubViewport
var game: AdventureGame
var results: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	root.size = Vector2i(2560, 1440)
	viewport = preload("res://tests/rendering_viewport.gd").create(root)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.gui_disable_input = true
	viewport.scaling_3d_scale = 1.0
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	_block_input(game)
	game.weather.set_physics_process(false)
	game.weather.set_phase(0)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.player.set_physics_process(false)
	game.player.relocate(game.parrot_travel.perches.stations[1].global_position + Vector3.UP * 0.1)
	game.parrot_travel.start(game.player)
	game.player.position.y += 8
	game.player.relocated.emit()
	game.player.transport_active = true
	game.player.velocity = Vector3.FORWARD * 24
	game.camera.reset_follow()
	game.parrot_travel.mounts._process(0)
	await process_frame
	print("PARROT DEVICE ", RenderingServer.get_video_adapter_name(), " / ", viewport.size, " scale=", viewport.scaling_3d_scale)
	await sample("overhead")
	game.camera.set_shoulder(true)
	game.camera.pitch = 0.12
	game.camera.yaw = 0
	await sample("behind")
	var bird: ParrotArt = game.parrot_travel.mounts.riders[game.player]
	bird.hide()
	await sample("behind_no_parrot")
	bird.show()
	var far_before := game.camera.far
	game.camera.far = 260
	await sample("behind_far_260")
	game.camera.far = far_before
	viewport.mesh_lod_threshold = 4.0
	await sample("behind_lod_4")
	viewport.mesh_lod_threshold = 1.0
	var grass := game.world.get_node("WildGrass") as Node3D
	grass.hide()
	await sample("behind_no_grass")
	grass.show()
	var sun := game.world.get_node("DirectionalLight3D") as DirectionalLight3D
	sun.shadow_enabled = false
	await sample("behind_no_shadows")
	var label := "after" if "--after" in OS.get_cmdline_user_args() else "before"
	var file := FileAccess.open("/tmp/tofufu-parrot-" + label + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	game.queue_free()
	await process_frame
	quit()

func sample(variant: String) -> void:
	for frame in 90: await process_frame
	var times: Array[float] = []
	var stamp := Time.get_ticks_usec()
	for frame in 240:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - stamp) / 1000.0)
		stamp = now
	times.sort()
	var row := {"variant": variant, "median_ms": times[120], "p95_ms": times[228], "draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "far": game.camera.far}
	row.merge(preload("res://tests/rendering_viewport.gd").dimensions(viewport))
	results.append(row)
	print("PARROT BENCH ", JSON.stringify(row))
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("/tmp/tofufu-parrot-bench-" + variant + ".png")

func _block_input(node: Node) -> void:
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	for child in node.get_children(): _block_input(child)
