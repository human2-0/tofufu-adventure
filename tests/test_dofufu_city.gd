extends SceneTree
## Full trail collision, real walking through seams/gates, atlas views and save migration.

class TestInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	var run: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.run_held = run
		command.move = move
		command.aim = move
		return command

var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	var mountains := game.world.dofufu_highlands.terrain
	await physics_frame
	var previous := mountains.trail_point(-110)
	var length: float = 110
	var max_slope: float = 0
	for index in 1480:
		var x := -110.5 - index * 0.5
		var at := mountains.trail_point(x)
		var flat := Vector2(at.x - previous.x, at.z - previous.z).length()
		max_slope = maxf(max_slope, absf(at.y - previous.y) / flat)
		length += at.distance_to(previous)
		previous = at
		var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 2, at - Vector3.UP * 2, 1)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y - at.y) < 0.04, "trail collision matches sampled surface at %s" % at)
	_check_camera_corridor(mountains, game.camera.offset)
	check(max_slope < 0.7, "continuous trail grade is walkable")
	print("Western trail: %.0f m / %.1f minutes at 6 m/s / max grade %.2f" % [length, length / 360, max_slope])
	check(length / 360 > 4.4 and length / 360 < 6.0, "approximately five-minute mixed travel")
	var old_west := Vector3(-120, -6, -100)
	check(TerrainLocomotion.saved_position(old_west, game.world).y > game.world.ground_point(-120, -100).y, "old saves below the expanded western ground recover onto its surface")
	var source := TestInput.new()
	game.player.add_child(source)
	game.player.command_source = source
	# Walk without jumping through the old boundary, across a tile seam, and through the east gate.
	for start in [Vector2(-103, 0), Vector2(-475, DofufuTerrain.trail_z(-475)), Vector2(-843, 0)]:
		game.player.position = game.world.ground_point(start.x, start.y, 0.1)
		game.player.velocity = Vector3.ZERO
		var target_x: float = start.x - 12
		for tick in 600:
			var goal := mountains.trail_point(target_x)
			var toward := Vector2(goal.x - game.player.position.x, goal.z - game.player.position.z)
			source.move = toward.normalized() if toward.length() > 0.2 else Vector2.ZERO
			game.player._physics_process(1.0 / 60)
			await physics_frame
		check(game.player.position.x < start.x - 8 and game.player.is_on_floor(), "ordinary walking crosses %s without jumping (ended %s)" % [start, game.player.position])
	game.player.position = game.world.ground_point(-925, -46, 0.1)
	game.player.velocity = Vector3.ZERO
	source.move = Vector2.UP
	for tick in 240:
		game.player._physics_process(1.0 / 60)
		await physics_frame
	check(game.player.position.z < -60 and game.player.is_on_floor(), "north city gate is physically open")
	# Traverse the complete marked route with real capsule sweeps in a static world.
	game.player.position = mountains.trail_point(-110) + Vector3.UP * 0.05
	game.player.velocity = Vector3.ZERO
	var travelled_ticks: int = 0
	source.run = true
	for tick in 30000:
		travelled_ticks = tick + 1
		if game.player.motor.endurance.current < 0.5: source.run = false
		if game.player.motor.endurance.current > 95: source.run = true
		var x := maxf(-844, game.player.position.x - 0.7)
		var goal := mountains.trail_point(x)
		var toward := Vector2(goal.x - game.player.position.x, goal.z - game.player.position.z)
		source.move = toward.normalized()
		game.player._physics_process(1.0 / 60)
		if tick % 60 == 0: await physics_frame
		if game.player.position.x <= -843.7: break
	check(game.player.position.x <= -843.7 and game.player.is_on_floor(), "entire winding mountain route traverses without jumps or teleports")
	print("Measured run/walk route including reserve recovery: %.1f minutes" % [(travelled_ticks / 60.0 + 110.0 / 6.0) / 60.0])
	var other_seed := DofufuTerrain.new(FarmTerrain.new(42))
	check(absf(other_seed.point(-475, 120).y - mountains.point(-475, 120).y) > 0.1, "mountain ridges change with seed")
	var world := CoopWorld.capture(game)
	check(WorldProtocol.valid(world) and world.mobs.size() == WorldProtocol.CURRENT_MOB_COUNT, "guard roster validates for saves and co-op")
	var guard := game.encounters.mob_nodes[55] as DofufuCityGuard
	game.player.position = guard.position + Vector3.RIGHT * 1.3
	guard.quarry = game.player
	guard._choose_direction(0.01)
	check(guard._windup > 0, "gate guard telegraphs attack")
	var attacks := [0]
	guard.attacked.connect(func(_amount: float, _at: Vector3) -> void: attacks[0] += 1)
	guard._choose_direction(0.7)
	check(attacks[0] == 1, "gate guard attacks a reachable opponent")
	var saved := EncounterState.mob(guard)
	guard.target.damage(9999)
	check(guard._respawn > 0 and not guard.visible, "guard defeats and respawns through authority")
	EncounterState.apply_mob(guard, saved, true)
	check(guard.target.current == saved[6] and guard.visible, "replica applies existing validated guard state")
	var map := MapExploration.new()
	map.reveal(Vector2(-930, 0))
	var restored := MapExploration.new()
	restored.restore(map.capture())
	check(restored.visited(Vector2(-930, 0)) and MapSaveValidation.valid(map.capture()), "western discoveries persist")
	var legacy := PackedByteArray()
	legacy.resize(25440)
	legacy.fill(0)
	var old_cell := Vector2i((Vector2.ZERO - Vector2(-142, -369)) / 2)
	var old_index := old_cell.y * 424 + old_cell.x
	legacy[old_index / 8] |= 1 << (old_index % 8)
	restored.restore(Marshalls.raw_to_base64(legacy))
	check(restored.visited(Vector2.ZERO), "old atlas discoveries retain world coordinates")
	for npc: DofufuResident in game.world.dofufu_highlands.city.residents.values():
		for view in 8:
			npc.art.present_direction(view)
			check(npc.art.current_cell == DofufuCityArt.CELLS[view] and npc.art.texture != null, "five views select for every observer direction")
	var sheet := DofufuCityArt.SHEET.get_image()
	for row in [1, 2, 3]:
		var stray := false
		for x in sheet.get_width():
			stray = stray or sheet.get_pixel(x, DofufuCityArt.ROWS[row]).a >= 0.3
		check(not stray, "city role %d starts in its own transparent gutter" % row)
	var adventure := AdventureSnapshot.capture(game, "Western Dofufu visit", 360)
	check(SaveStore.valid(adventure), "western position and expanded map form a valid adventure save")
	check(JSON.stringify(adventure).to_utf8_buffer().size() < 98304, "expanded atlas fits the adventure save cap")
	other_seed = null
	var bad := world.duplicate(true)
	bad.mobs[55][6] = 10000
	check(not WorldProtocol.valid(bad), "malformed guard health rejected")
	check(ExplorationProtocol.vector([-950, 11, 0], 3, 1000), "western city fits finite protocol position bounds")
	for i in 4: await physics_frame
	game.queue_free()
	for i in 4: await process_frame
	print("Dofufu city: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _check_camera_corridor(terrain: DofufuTerrain, offset: Vector3) -> void:
	var minimum: float = 1000
	for x in range(-112, -850, -2):
		var at := terrain.trail_point(x)
		for direction in 4:
			var camera := at + offset.rotated(Vector3.UP, direction * PI / 2)
			for segment in range(1, 21):
				var sample := (at + Vector3.UP).lerp(camera, segment / 20.0)
				minimum = minf(minimum, sample.y - terrain.point(sample.x, sample.z).y)
	check(minimum > 0.5, "all four normal overhead views retain clear sightlines along the entire trail")
