extends SceneTree
## Local rendered match cost with JSON fanout. This is not WAN/device acceptance.
var _bytes: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var resolution := Vector2i(2560, 1440) if "--1440p" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	root.size = resolution
	root.content_scale_size = resolution
	var room := BattleRoom.new()
	root.add_child(room)
	room.practice()
	room.epoch = "b".repeat(24) # Repeat the same spawn, loot layout and camera view.
	var game := BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	var loot_stress := "--loot" in OS.get_cmdline_user_args()
	if loot_stress: _loot(game)
	var settings := GamePreferences.new()
	RenderBudget.install(game, settings, func() -> bool: return game.playing)
	var results: Array = []
	for humans in [1, 20]:
		room.members.clear()
		room.connected.clear()
		for i in humans:
			var key := "%064x" % (i + 1)
			room.members.append({"key": key, "name": "Bean %d" % i, "skin": i % 8})
			room.connected[key] = true
		room.local_key = room.members[0].key
		room.host_key = room.local_key
		room.offline = humans == 1
		room.send_packet = func(key: String, packet: Dictionary) -> void:
			_bytes += JSON.stringify(packet).to_utf8_buffer().size()
			if packet.get("kind") == "br_checkpoint": room.migration.receive(key, {"kind": "br_lease", "epoch": room.epoch, "term": room.term, "seq": room.migration.checkpoint_seq})
		room.send_batch = func(keys: Array[String], packet: Dictionary) -> void:
			if keys.is_empty(): return
			_bytes += JSON.stringify(packet).to_utf8_buffer().size() * keys.size()
			if packet.get("kind") == "br_checkpoint":
				for key: String in keys: room.migration.receive(key, {"kind": "br_lease", "epoch": room.epoch, "term": room.term, "seq": room.migration.checkpoint_seq})
		game.match_state.time = 13
		for slot in 20: game.match_state.rows[slot][17] = int(slot >= humans)
		_bytes = 0
		var times: Array[float] = []
		var minimum_alive: int = 20
		var started := Time.get_ticks_usec()
		for tick in 480:
			if tick == 120:
				_bytes = 0
				started = Time.get_ticks_usec()
			# Keep all twenty capsules active throughout both measured workloads.
			game.match_state.alive = 20
			game.match_state.winner = -2
			for slot in 20:
				game.match_state.rows[slot][8] = 100.0
				game.match_state.rows[slot][9] = 100.0
				game.match_state.rows[slot][13] = 0
				game.bodies[slot].collision_layer = 2
			if humans > 1 and tick % 3 == 0:
				for slot in range(1, 20):
					var packet := {"kind": "br_input", "epoch": room.epoch, "term": room.term, "seq": tick / 3 + 1, "inputs": [[slot, BattleBot.command(slot, game.match_state)]]}
					game.replication.receive(room.members[slot].key, packet)
			var before := Time.get_ticks_usec()
			game._physics_process(1.0 / 60)
			if tick >= 120: times.append((Time.get_ticks_usec() - before) / 1000.0)
			minimum_alive = mini(minimum_alive, game.match_state.alive)
			await physics_frame
		var wall_seconds := (Time.get_ticks_usec() - started) / 1000000.0
		times.sort()
		results.append({"human_seats": humans, "cpu_seats": 20 - humans, "minimum_alive": minimum_alive, "simulation_and_json_p95_ms": times[int(times.size() * 0.95)],
			"simulation_and_json_max_ms": times.back(), "json_upload_bytes_per_simulated_second": _bytes / 6.0,
			"elapsed_wall_seconds": wall_seconds, "engine_fps": Performance.get_monitor(Performance.TIME_FPS),
			"render_scale": root.scaling_3d_scale,
			"rendered_objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	var report := {"renderer": DisplayServer.get_name(), "viewport": [resolution.x, resolution.y], "target_fps": settings.frame_limit, "adaptive_resolution": settings.adaptive_resolution, "loot_stress": loot_stress, "warmup_frames_per_profile": 120, "measured_frames_per_profile": 360, "results": results,
		"scope": "Production render budget, one shared IPC serialization per broadcast and one local map; nineteen recipients are serialized fakes. Actual encrypted twenty-peer traffic is a separate sidecar test. No separate-device or WAN FPS guarantee."}
	var output := "/tmp/tofufu-battle-benchmark-1440p.json" if resolution.x == 2560 else "/tmp/tofufu-battle-benchmark.json"
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report))
	game.queue_free()
	room.queue_free()
	await process_frame
	quit()

func _loot(game: BattleRoyaleGame) -> void:
	for slot in 20:
		var fighter := game.combat.fighters[slot]
		fighter.loadout.equipment.set_slot("backpack", ItemStack.new(BattleItems.make(26), 1))
		for i in 20: fighter.loadout.inventory.set_slot(i, ItemStack.new(BattleItems.make([3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16, 20, 13, 17, 21, 24, 25, 27, 28, 32][i]), 1))
		for i in 4: fighter.loadout.equipment.set_slot(CharacterEquipment.APPAREL_SLOTS[i], ItemStack.new(BattleItems.make(12 + (slot % 3) * 4 + i), 1))
		game.pack.healing[slot].apple_duration_remaining = 125
		game.pack.refresh(slot)
	for chest: Array in game.match_state.chests:
		chest[4] = 1
		for kind in BattleChestLoot.contents(game.room.epoch, int(chest[0])):
			game.pack.spawn(ItemStack.new(BattleItems.make(kind), 1), Vector3(chest[1], chest[2], chest[3]) + Vector3(2, 0, 0))
	game.pack.capture(true)
	game.pack.field.update(false)
