extends SceneTree
## Same locations in all views, native 1440p. Ablations never alter gameplay defaults.

var viewport: SubViewport
var game: AdventureGame
var results: Array[Dictionary] = []
var materials: Array[Material] = []
var passes: Array[Material] = []

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Perspective benchmark requires a rendered window.")
		quit(1)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(2560, 1440)
	viewport = preload("res://tests/rendering_viewport.gd").create(root)
	viewport.scaling_3d_scale = 1.0
	if "--no-occlusion" in OS.get_cmdline_user_args(): viewport.use_occlusion_culling = false
	root.gui_disable_input = true
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	_block_input(game)
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.weather.set_physics_process(false)
	game.weather.set_phase(0.05)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	_collect_materials(game.world)
	print("PERSPECTIVE DEVICE ", RenderingServer.get_video_adapter_name(), " / ", root.size)
	var places := {"village": Vector2(33, -22), "grass": Vector2(-40, 18), "reef": Vector2(0, -145), "castle": Vector2(316, 355), "clouds": Vector2(-40, 314)}
	if "--quick" in OS.get_cmdline_user_args(): places = {"village": places.village, "grass": places.grass}
	if "--cloud-diagnose" in OS.get_cmdline_user_args(): places = {"clouds": places.clouds}
	for place: String in places:
		var point: Vector2 = places[place]
		var at := game.world.ground_point(point.x, point.y, 0.1)
		if place == "clouds": at = Vector3(point.x, CloudTerrain.ALTITUDE + 0.1, point.y)
		game.player.relocate(at)
		for mode in ["overhead", "shoulder", "first_person"]:
			var wanted := 2 if mode == "first_person" else (1 if mode == "shoulder" else 0)
			while (2 if game.shooting_view.first_person else (1 if game.shooting_view.shoulder else 0)) != wanted:
				game.shooting_view.cycle_mode()
			game.camera.yaw = 0.0
			game.camera.pitch = 0.12
			game.camera.reset_follow()
			game.camera._follow(1.0)
			await sample(place, mode, "normal")
			if "--cloud-diagnose" in OS.get_cmdline_user_args() and mode == "first_person":
				for region in [game.world.ocean, game.world.frost, game.world.desert, game.world.jungle, game.world.volcanic, game.world.cloud_realm]:
					region.hide()
					await sample(place, mode, "no_" + region.name)
					region.show()
			if not "--ablation" in OS.get_cmdline_user_args() or mode == "overhead": continue
			viewport.use_occlusion_culling = false
			await sample(place, mode, "no_occlusion")
			viewport.use_occlusion_culling = true
			game.process_mode = Node.PROCESS_MODE_DISABLED
			await sample(place, mode, "no_scripts")
			game.process_mode = Node.PROCESS_MODE_INHERIT
			var grass: Node3D = game.world.get_node("WildGrass")
			grass.hide()
			await sample(place, mode, "no_grass")
			grass.show()
			var sun: DirectionalLight3D = game.world.get_node("DirectionalLight3D")
			sun.shadow_enabled = false
			await sample(place, mode, "no_shadows")
			sun.shadow_enabled = true
			for material in materials: material.next_pass = null
			await sample(place, mode, "no_outlines")
			for i in materials.size(): materials[i].next_pass = passes[i]
			viewport.mesh_lod_threshold = 4.0
			await sample(place, mode, "lod_4")
			viewport.mesh_lod_threshold = 1.0
			viewport.scaling_3d_scale = 0.85
			await sample(place, mode, "scale_85")
			viewport.scaling_3d_scale = 1.0
	var path := "/tmp/tofufu-perspectives-no-occlusion.json" if "--no-occlusion" in OS.get_cmdline_user_args() else "/tmp/tofufu-perspectives.json"
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	game.queue_free()
	await process_frame
	await process_frame
	quit()

func sample(place: String, mode: String, variant: String) -> void:
	for frame in 90: await process_frame
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	var cpu: float = 0.0
	var physics: float = 0.0
	for frame in 240:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid())
		physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	times.sort()
	var row := {"place": place, "camera_mode": mode, "variant": variant, "median_ms": times[120], "p95_ms": times[228], "draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), "render_cpu_ms": cpu / 240, "physics_ms": physics / 240, "scale": viewport.scaling_3d_scale, "occlusion": viewport.use_occlusion_culling}
	row.merge(preload("res://tests/rendering_viewport.gd").dimensions(viewport))
	results.append(row)
	print("PERSPECTIVE BENCH ", JSON.stringify(row))
	if variant == "normal":
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("/tmp/tofufu-perspective-%s-%s.png" % [place, mode])

func _block_input(node: Node) -> void:
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	for child in node.get_children(): _block_input(child)

func _collect_materials(node: Node) -> void:
	var mesh: Mesh = node.mesh if node is MeshInstance3D else (node.multimesh.mesh if node is MultiMeshInstance3D else null)
	if mesh != null:
		for i in mesh.get_surface_count():
			var material: Material = node.material_override if node.material_override != null else mesh.surface_get_material(i)
			if material != null and material.next_pass != null and material not in materials:
				materials.append(material)
				passes.append(material.next_pass)
	for child in node.get_children(): _collect_materials(child)
