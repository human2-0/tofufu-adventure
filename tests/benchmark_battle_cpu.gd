extends SceneTree
## Native, isolated offline CPU-count comparison. No network/FPS guarantee.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	TranslationServer.set_locale("en")
	var args := OS.get_cmdline_user_args()
	var destination := args[1] if args.size() > 1 else ".codex/visualizations/2026/10/20/battle-fifty-cpus"
	var output := ProjectSettings.globalize_path("res://").path_join(destination)
	DirAccess.make_dir_recursive_absolute(output)
	var cpus := int(args[0]) if not args.is_empty() else 7
	assert(cpus >= 1 and cpus <= 50)
	root.size = Vector2i(1280, 720)
	var viewport: SubViewport = load("res://tests/rendering_viewport.gd").create(root)
	var room := BattleRoom.new()
	room.options = [cpus, 1]
	root.add_child(room)
	room.practice()
	room.epoch = "b".repeat(24)
	var game := BattleRoyaleGame.new()
	game.room = room
	viewport.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	var hunts_enabled := not args.has("without-hunts")
	if not hunts_enabled:
		for enemy in game.mobs.actors:
			for fighter in game.combat.fighters: fighter.combat.targets.erase(enemy.target)
			enemy.free()
		game.mobs.actors.clear()
		game.mobs.awake.clear()
		game.match_state.mobs.clear()
	var preferences := GamePreferences.new()
	RenderBudget.install(game, preferences, func() -> bool: return game.playing)
	# Retain the same active population throughout; outcomes are tested elsewhere.
	for slot in game.bodies.size():
		game.combat.fighters[slot].health.attack_receiver = func(_amount: float, direction: Vector3, kind: Damageable.HitKind, point: Vector3, source: Damageable) -> bool:
			return game.combat.receive(0.0, direction, kind, point, source, slot)
	game.match_state.time = 13
	var samples: Array[float] = []
	var minimum_alive := game.match_state.alive
	var awake_hunts := 0
	for tick in 480:
		var before := Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		if tick >= 120: samples.append((Time.get_ticks_usec() - before) / 1000.0)
		minimum_alive = mini(minimum_alive, game.match_state.alive)
		awake_hunts = maxi(awake_hunts, game.mobs.awake.count(true))
		await physics_frame
	samples.sort()
	var report := {"cpus": cpus, "difficulty": "normal", "survivors": game.bodies.size(),
		"minimum_alive": minimum_alive, "hunts_enabled": hunts_enabled, "hunts": game.mobs.actors.size(), "maximum_awake_hunts": awake_hunts, "viewport": [viewport.get_texture().get_width(), viewport.get_texture().get_height()],
		"renderer": DisplayServer.get_name(), "simulation_p50_ms": samples[int(samples.size() * 0.5)],
		"simulation_p95_ms": samples[int(samples.size() * 0.95)], "simulation_max_ms": samples.back(),
		"engine_fps": Performance.get_monitor(Performance.TIME_FPS), "render_scale": viewport.scaling_3d_scale,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"warmup_ticks": 120, "measured_ticks": samples.size(),
		"scope": "One native offline map, constant invulnerable population, 1440p viewport with production adaptive resolution. Includes movement, bot decisions, combat and pack capture. Run without other test workers. Not WAN/device acceptance or a locked FPS guarantee."}
	var path := output + ("/benchmark-%d.json" if hunts_enabled else "/benchmark-%d-without-hunts.json") % cpus
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	if cpus == 50 and hunts_enabled:
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output + "/game-50-en.png")
	game.queue_free()
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(0 if minimum_alive == cpus + 1 and viewport.size == Vector2i(2560, 1440) else 1)
