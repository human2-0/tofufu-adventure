extends SceneTree
## Rendered 1440p benchmark. Run without --headless; -- --ablation isolates costs.

var viewport: SubViewport
var game: AdventureGame
var results: Array[Dictionary] = []
var ablation: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Benchmark requires a GPU/window.")
		quit(1)
		return
	ablation = "--ablation" in OS.get_cmdline_user_args()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	root.size = Vector2i(2560, 1440)
	viewport = preload("res://tests/rendering_viewport.gd").create(root)
	root.gui_disable_input = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	_block_input(game)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.player.set_physics_process(false)
	print("BENCH device=", RenderingServer.get_video_adapter_name(), " size=", viewport.size, " scale=", viewport.scaling_3d_scale)
	var meshes: Array[Dictionary] = []
	for node in game.world.find_children("*", "MeshInstance3D", true, false):
		var view := node as MeshInstance3D
		if view.mesh == null: continue
		var count := 0
		for i in view.mesh.get_surface_count():
			var arrays := view.mesh.surface_get_arrays(i)
			count += arrays[Mesh.ARRAY_INDEX].size() / 3 if arrays[Mesh.ARRAY_INDEX] != null and arrays[Mesh.ARRAY_INDEX].size() > 0 else arrays[Mesh.ARRAY_VERTEX].size() / 3
		meshes.append({"path": str(view.get_path()), "triangles": count})
	meshes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.triangles > b.triangles)
	print("MESHES ", JSON.stringify(meshes.slice(0, 12)))
	var places: Array[String] = ["village", "grass", "shore", "waterfall", "volcanic", "thermal_gardens", "obsidian_sanctuary", "castle", "clouds"]
	if "--diagnose" in OS.get_cmdline_user_args(): places = ["village", "volcanic"]
	if "--volcanic" in OS.get_cmdline_user_args(): places = ["volcanic", "thermal_gardens", "obsidian_sanctuary", "castle"]
	for place: String in places:
		var at := Vector3(33, 0, -22)
		match place:
			"grass": at = Vector3(-40, 0, 18)
			"shore": at = Vector3(0, 0, -145)
			"waterfall": at = Vector3(-40, 2, 307)
			"volcanic": at = Vector3(274, 0, 412)
			"thermal_gardens": at = Vector3(585, 5, 324)
			"obsidian_sanctuary": at = Vector3(573, 11, 456)
			"castle": at = Vector3(316, 5, 355)
			"clouds": at = Vector3(-40, 100, 300)
		at = game.world.ground_point(at.x, at.z) if place != "clouds" else Vector3(-40, CloudTerrain.ALTITUDE, 314)
		game.player.position = at + Vector3.UP
		game.camera.position = at + game.camera.offset
		game.camera.look_at(at + Vector3.UP)
		await sample(place, "normal")
		if "--diagnose" in OS.get_cmdline_user_args():
			var sky := game.cycle.world_environment.environment.sky
			var simple := ProceduralSkyMaterial.new()
			sky.sky_material = simple
			await sample(place, "simple_sky")
			sky.sky_material = game.cycle.sky_effects.material
			game.process_mode = Node.PROCESS_MODE_DISABLED
			await sample(place, "no_scripts")
			game.process_mode = Node.PROCESS_MODE_INHERIT
			var sun := game.world.get_node("DirectionalLight3D") as DirectionalLight3D
			sun.directional_shadow_max_distance = 32.0
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			for node in game.world.find_children("*", "MeshInstance3D", true, false):
				if (node as MeshInstance3D).mesh != null and (node as MeshInstance3D).mesh.get_aabb().size.length() > 100:
					(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			await sample(place, "bounded_shadows")
			game.process_mode = Node.PROCESS_MODE_DISABLED
			await sample(place, "bounded_no_scripts")
			game.process_mode = Node.PROCESS_MODE_INHERIT
		if not ablation: continue
		game.world.volcanic.ocean.visible = false
		await sample(place, "no_coastal_water")
		game.world.volcanic.ocean.visible = true
		var grass := game.world.get_node("WildGrass") as Node3D
		grass.visible = false
		await sample(place, "no_grass")
		grass.visible = true
		var sun := game.world.get_node("DirectionalLight3D") as DirectionalLight3D
		sun.shadow_enabled = false
		await sample(place, "no_shadows")
		sun.shadow_enabled = true
		viewport.scaling_3d_scale = 0.75
		await sample(place, "scale_75")
		viewport.scaling_3d_scale = 1.0
	var file := FileAccess.open("/tmp/tofufu-benchmark.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "\t"))
	game.queue_free()
	await process_frame
	quit()

func _block_input(node: Node) -> void:
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	for child in node.get_children(): _block_input(child)

func sample(place: String, variant: String) -> void:
	for frame in 90: await process_frame
	var times: Array[float] = []
	var gpu: float = 0.0
	var cpu: float = 0.0
	var last := Time.get_ticks_usec()
	for frame in 240:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid())
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid())
	times.sort()
	var result := {"place": place, "variant": variant, "median_ms": times[120], "p95_ms": times[228], "gpu_ms": gpu / 240 if gpu > 0 else null, "render_cpu_ms": cpu / 240, "draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0}
	result.merge(preload("res://tests/rendering_viewport.gd").dimensions(viewport))
	results.append(result)
	print("BENCH ", JSON.stringify(result))
	if variant == "normal":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/tofufu-bench-" + place + ".png")
