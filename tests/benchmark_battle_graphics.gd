extends SceneTree
## Same-world ABBA isolates scenery/shadow/pixel cost from bot simulation and loading.
const OUTPUT := "res://.codex/visualizations/2026/10/23/royale-performance/"
var game: BattleRoyaleGame
var viewport: SubViewport
var samples: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1280, 720)
	viewport = load("res://tests/rendering_viewport.gd").create(root)
	var room := BattleRoom.new()
	room.options = [50, 1]
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.room = room
	viewport.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	room.set_process(false)
	for child in game.get_children():
		if child is BattleAimView:
			child.set_process(false)
			child.set_process_unhandled_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for region: String in ["meadow", "city"]:
		var center := Vector2(-22, -2) if region == "meadow" else Vector2(480, 60)
		for slot in game.bodies.size():
			var at := center + Vector2(slot % 8 - 4, floori(slot / 8.0) - 3) * 2
			game.bodies[slot].position = game.world.ground_point(at.x, at.y, 0.08)
		game.bodies[0].position = game.world.ground_point(center.x, center.y, 0.08)
		game.camera.yaw = 0
		game.camera.reset_follow()
		for performance in [false, true, true, false]: await _sample(region, performance)
	var file := FileAccess.open(OUTPUT + "graphics-abba.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"scope": "Native M1 fixed 2560x1440 target, uncapped, 51 fixed-pose survivors. Same loaded world/camera, ABBA at meadow and city. Full scenery/shadows at fixed 90% versus near scenery/no shadows at 65%. Bot simulation and network frozen; this isolates graphics and does not promise active 50-CPU FPS.", "samples": samples}, "\t"))
	file.close()
	game.queue_free()
	room.queue_free()
	await process_frame
	print("Royale graphics ABBA: PASS")
	quit()

func _sample(region: String, performance: bool) -> void:
	var settings := game.preferences.graphics
	settings.set_scenery(160 if performance else 0, not performance)
	viewport.scaling_3d_scale = 0.65 if performance else 0.9
	var frames: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 180:
		game.presentation.update(1.0 / 60)
		await process_frame
		var now := Time.get_ticks_usec()
		if frame >= 60: frames.append((now - previous) / 1000.0)
		previous = now
	frames.sort()
	var report := {"region": region, "performance": performance, "frame_p50_ms": frames[60], "frame_p95_ms": frames[114],
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	samples.append(report)
	print(JSON.stringify(report))
