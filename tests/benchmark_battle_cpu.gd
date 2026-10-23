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
	if args.has("honio"): room.epoch = "0".repeat(24)
	var game := BattleRoyaleGame.new()
	game.preferences.path = "user://battle-cpu-benchmark-%d.cfg" % Time.get_ticks_usec()
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
	var preferences := game.preferences
	RenderBudget.install(game, preferences, func() -> bool: return game.playing)
	if args.has("performance"):
		game.settings._performance()
		game.settings.panel.hide()
		game.hud.exit_panel.hide()
	root.grab_focus()
	# Retain the same active population throughout; outcomes are tested elsewhere.
	for slot in game.bodies.size():
		game.combat.fighters[slot].health.attack_receiver = func(_amount: float, direction: Vector3, kind: Damageable.HitKind, point: Vector3, source: Damageable) -> bool:
			return game.combat.receive(0.0, direction, kind, point, source, slot)
	game.match_state.time = 13
	var honio_id := -1
	if args.has("honio") and hunts_enabled:
		honio_id = BattleHonioSpawn.site(room.epoch, game.mobs.actors.size())
		var honio := game.mobs.actors[honio_id] as HonioMeniono
		var at := game.bodies[0].position
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.6, 2.2, 2.6)
		for angle in 16:
			var nearby := game.world.ground_point(at.x + cos(angle * TAU / 16) * 8, at.z + sin(angle * TAU / 16) * 8, 0.08)
			if game.world.is_water(nearby): continue
			if not BattlePlantLayout._flat(game, nearby) or not BattleChestLayout.clear(game, nearby, shape): continue
			honio.position = nearby
			honio._home = nearby
			break
		# Keep the rare encounter active throughout this constant-population fixture.
		honio.target.damage_filter = func(_amount: float, _direction: Vector3, _kind: Damageable.HitKind) -> float: return 0
	var honio_awake_ticks := 0
	var safe_positions: Array[Vector3] = []
	var void_resets: Array = []
	for body: Player in game.bodies: safe_positions.append(body.position)
	var samples: Array[float] = []
	var minimum_alive := game.match_state.alive
	var awake_hunts := 0
	var frame_times: Array[float] = []
	var frame_clock: Array[int] = [Time.get_ticks_usec(), 0]
	var collect_frame := func() -> void:
		var now := Time.get_ticks_usec()
		if frame_clock[1] > 0: frame_times.append((now - frame_clock[0]) / 1000.0)
		frame_clock[0] = now
	process_frame.connect(collect_frame)
	for tick in 480:
		for slot in game.bodies.size():
			var body := game.bodies[slot]
			if body.position.y >= -30: continue
			void_resets.append([slot, tick, body.position.x, body.position.y, body.position.z])
			body.position = safe_positions[slot]
			body.velocity = Vector3.ZERO
		if tick == 120:
			frame_clock[0] = Time.get_ticks_usec()
			frame_clock[1] = 1
		var before := Time.get_ticks_usec()
		game._physics_process(1.0 / 60)
		if tick >= 120: samples.append((Time.get_ticks_usec() - before) / 1000.0)
		minimum_alive = mini(minimum_alive, game.match_state.alive)
		awake_hunts = maxi(awake_hunts, game.mobs.awake.count(true))
		if honio_id >= 0 and game.mobs.awake[honio_id]: honio_awake_ticks += 1
		await physics_frame
	process_frame.disconnect(collect_frame)
	samples.sort()
	frame_times.sort()
	var report := {"cpus": cpus, "difficulty": "normal", "survivors": game.bodies.size(),
		"minimum_alive": minimum_alive, "hunts_enabled": hunts_enabled, "hunts": game.mobs.actors.size(), "maximum_awake_hunts": awake_hunts, "viewport": [viewport.get_texture().get_width(), viewport.get_texture().get_height()],
		"renderer": DisplayServer.get_name(), "simulation_p50_ms": samples[int(samples.size() * 0.5)],
		"simulation_p95_ms": samples[int(samples.size() * 0.95)], "simulation_max_ms": samples.back(),
		"engine_fps": Performance.get_monitor(Performance.TIME_FPS), "render_scale": viewport.scaling_3d_scale,
		"frame_samples": frame_times.size(), "frame_p50_ms": frame_times[int(frame_times.size() * 0.5)],
		"frame_p95_ms": frame_times[int(frame_times.size() * 0.95)], "mean_fps": frame_times.size() * 1000.0 / _sum(frame_times),
		"scenery_distance": preferences.graphics.scenery_distance, "shadows": preferences.graphics.shadows,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"warmup_ticks": 120, "measured_ticks": samples.size(),
		"fixture_void_resets": void_resets,
		"scope": "One native offline map, constant invulnerable population, fixed 1440p viewport and production graphics settings. Test-only void resets keep all actors active. Includes movement, bot decisions, combat and pack capture. Run without other test workers. Not WAN/device acceptance or a locked FPS guarantee."}
	report.merge(_chest_distances(game))
	report.merge({"honio_site": honio_id, "honio_awake_ticks": honio_awake_ticks})
	var path := output + ("/benchmark-%d.json" if hunts_enabled else "/benchmark-%d-without-hunts.json") % cpus
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	if cpus == 50 and hunts_enabled:
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(output + "/game-50-en.png")

	game.queue_free()
	DirAccess.remove_absolute(game.preferences.path)
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	var active_encounter := honio_id < 0 or honio_awake_ticks >= 360
	quit(0 if minimum_alive == cpus + 1 and viewport.size == Vector2i(2560, 1440) and active_encounter else 1)

func _chest_distances(game: BattleRoyaleGame) -> Dictionary:
	var distances: Array[float] = []
	for site: Array in game.match_state.deployment.sites:
		var nearest := INF
		for chest: Array in game.match_state.chests:
			nearest = minf(nearest, Vector2(site[0] - chest[1], site[2] - chest[3]).length())
		distances.append(nearest)
	distances.sort()
	return {"chests": game.match_state.chests.size(), "plant_to_chest_p50_m": distances[int(distances.size() * 0.5)], "plant_to_chest_p95_m": distances[int(distances.size() * 0.95)], "plant_to_chest_max_m": distances.back()}

func _sum(values: Array[float]) -> float:
	var total := 0.0
	for value in values: total += value
	return total
