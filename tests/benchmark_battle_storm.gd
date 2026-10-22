extends SceneTree
## Isolate the new presentation cost at 1440p; fixed actors are not a CPU/WAN test.
const OUTPUT := "res://.codex/visualizations/2026/10/22/battle-hud/"
var game: BattleRoyaleGame
var samples: Array[Dictionary] = []

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	var viewport: SubViewport = load("res://tests/rendering_viewport.gd").create(root)
	viewport.scaling_3d_scale = 0.9
	var room := BattleRoom.new()
	room.options = [50, 1]
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.room = room
	viewport.add_child(game)
	while not game.composed: await physics_frame
	room.set_process(false)
	game.set_physics_process(false)
	BattleTestDeployment.finish(game)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.match_state.time = BattleRing.start_of(5) + BattleRing.HOLD + 1
	game.match_state.circle = BattleRing.CENTER
	for slot in game.bodies.size():
		var at := Vector2(-22, -22) + Vector2(slot % 8 - 4, floori(slot / 8.0) - 3) * 2
		game.bodies[slot].position = game.world.ground_point(at.x, at.y, 0.08)
	game.bodies[0].position = game.world.ground_point(-22, -2, 0.08)
	game.camera.yaw = 0
	game.camera.reset_follow()
	game._update_hud()
	for enabled in [false, true, true, false]: await _sample(enabled)
	var file := FileAccess.open(OUTPUT + "storm-performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"disabled_pass": "Wall, rim and vignette are hidden after identical CPU preparation, isolating rendering cost.", "scope": "Native M1, 2560x1440 at fixed 90% render scale, 51 fixed-pose actors, close storm wall filling the view. ABBA presentation comparison; simulation/networking are frozen. This isolates visual cost and is not an active 50-CPU FPS guarantee.", "samples": samples}, "\t"))
	file.close()
	game.queue_free()
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("Native storm presentation comparison: PASS")
	quit()

func _sample(enabled: bool) -> void:
	var frames: Array[float] = []
	var preparation: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 360:
		var before := Time.get_ticks_usec()
		game.presentation.update(1.0 / 60)
		if not enabled:
			game.presentation.storm.wall.hide()
			game.presentation.storm.rim.hide()
			game.presentation.storm.edge.hide()
		if frame >= 120: preparation.append((Time.get_ticks_usec() - before) / 1000.0)
		await process_frame
		var now := Time.get_ticks_usec()
		if frame >= 120: frames.append((now - previous) / 1000.0)
		previous = now
	frames.sort()
	preparation.sort()
	var report := {"storm": enabled, "frame_p50_ms": frames[120], "frame_p95_ms": frames[228], "preparation_p95_ms": preparation[228], "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	samples.append(report)
	print(JSON.stringify(report))
