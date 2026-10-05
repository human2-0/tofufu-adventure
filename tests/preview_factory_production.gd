extends SceneTree
## Render the authored machinery beside the real Fufu capsule and billboard art.

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("a6beb8")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("fff0d1")
	environment.environment.ambient_light_energy = 0.8
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_energy = 1.2
	stage.add_child(sun)
	var factory := TofuFactory.new()
	stage.add_child(factory)
	factory.ensure_interior()
	for legacy in factory._displays: legacy.visible = false
	for legacy in factory._bags: legacy.visible = false
	var player: Player = load("res://game/player/player.tscn").instantiate()
	stage.add_child(player)
	player.set_physics_process(false)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	var snapshot := TofuDungeonAttempt.new().capture()
	snapshot.lab.shelf_order = FactoryLayout.CHEMICAL_IDS.duplicate()
	snapshot.sorting.assignments = {"sack_mature": "intake_tofu"}
	FactoryProductionVisuals.present_factory(factory, snapshot)
	for view in get_nodes_in_group("factory_production_visuals"):
		if (view as FactoryProductionVisuals).room == 0:
			(view.get_parent().get_node("BatchLine") as FactoryBatchLine)._process(10.0)
	FactoryProductionVisuals.present_factory(factory, snapshot)
	for room in [0, 1, 2, 3, 4]:
		var center: Vector3 = TofuFactory.CENTERS[room]
		player.relocate(center + Vector3(0, 0.2, 2))
		camera.position = center + Vector3(0, 10, 12)
		camera.look_at(center + Vector3(0, 0.8, -2))
		await _save("/tmp/tofufu-production-room-%d.png" % room)
	camera.position = Vector3(321.2, 1.55, -184.2)
	camera.look_at(Vector3(321.2, 1.62, -187))
	await _save("/tmp/tofufu-production-labels.png")
	camera.position = Vector3(335, 1.5, -180)
	camera.look_at(Vector3(339, 1.1, -185))
	await _save("/tmp/tofufu-production-press.png")
	camera.position = Vector3(349, 1.7, -182.5)
	camera.look_at(Vector3(349, 1.7, -185))
	await _save("/tmp/tofufu-production-modern-calibration.png")
	camera.position = Vector3(338, 1.7, -182.5)
	camera.look_at(Vector3(338, 1.8, -185.5))
	await _save("/tmp/tofufu-production-traditional-card.png")
	await _moving_floor(camera, player)
	print("Factory production previews: saved /tmp/tofufu-production-*.png")
	stage.queue_free()
	await process_frame
	await process_frame
	quit()

func _save(path: String) -> void:
	for frame in 8: await process_frame
	var cpu: float = 0.0
	var draws: float = 0.0
	var objects: float = 0.0
	var started: int = Time.get_ticks_usec()
	for frame in 32:
		await process_frame
		cpu += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var frame_ms: float = (Time.get_ticks_usec() - started) / 32000.0
	print("%s: frame %.2f ms, process monitor %.2f ms, %.0f draws, %.0f rendered objects (32-frame mean)" % [path.get_file(), frame_ms, cpu / 32.0, draws / 32.0, objects / 32.0])
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _moving_floor(camera: Camera3D, player: Player) -> void:
	player.relocate(Vector3(294, 0.2, -178))
	var observed := Vector3(301, 0.003, -175)
	var first := Color()
	var variation: float = 0.0
	for frame in 24:
		var shift: float = frame / 23.0 * 4.0 - 2.0
		camera.position = Vector3(300 + shift, 7, -168)
		camera.look_at(Vector3(300 + shift, 0.6, -180))
		await process_frame
		await RenderingServer.frame_post_draw
		var rendered: Image = root.get_texture().get_image()
		var pixel: Vector2 = camera.unproject_position(observed)
		var color: Color = rendered.get_pixel(int(pixel.x), int(pixel.y))
		if frame == 0: first = color
		variation = maxf(variation, maxf(absf(color.r - first.r), maxf(absf(color.g - first.g), absf(color.b - first.b))))
		if frame in [0, 12, 23]: rendered.save_png("/tmp/tofufu-production-moving-floor-%02d.png" % frame)
	print("Moving Metal floor sample: maximum channel change %.4f across 24 camera positions" % variation)
	if variation > 0.02:
		push_error("Moving floor changed flat-surface color; inspect depth fighting")
		quit(1)
