extends SceneTree
## Full maze route collision sweeps, physical stair ascent, lava authority and saves.

class WalkInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	var rise: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.jump_held = rise
		return command

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for i in count: await physics_frame

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.player.movement_modifier = Callable()
	await ticks(4)
	var island := game.world.volcanic
	var castle := island.castle
	var actor := game.player
	actor.set_physics_process(false)
	var space := actor.get_world_3d().direct_space_state
	check(VolcanicTerrain.height_at(160, 330) < -7, "channel has no unintended connecting land strip")
	check(game.world.is_water(Vector3(160, -5, 310)), "wide open ocean separates jungle and volcanic land")
	check(TerrainLocomotion.immersion(Vector3(160, -5, 310), game.world) == 1, "channel supports underwater movement")
	check(game.world.ground_point(336, 308).is_equal_approx(island.point(336, 308)), "world dispatch uses volcanic terrain")
	check(game.parrot_travel.perches.stations.size() == 8, "continent has a return parrot")
	check(game.parrot_travel.perches.stations[6].position.is_equal_approx(CloudTerrain.point(-8, 247, 0.05)), "adding continent retains elevated cloud perch")
	check(not game.world.is_water(game.parrot_travel.perches.stations[7].position), "volcanic landing is on dry beach")
	check(game.world.map_npcs.has("Tofufu King Lava · Royal Plaza"), "King has a map destination")
	check(castle.king.sprite.texture is AtlasTexture, "elderly king uses calibrated directional character art")
	check(VolcanicTerrain.VOLCANO == VolcanicTerrain.CENTER, "volcano is the geographic center of the island")
	check(VolcanicTerrain.VOLCANO_RADIUS == 100 and VolcanicTerrain.VOLCANO_HEIGHT == 136, "volcano doubles its original fifty-metre radius and sixty-eight-metre rise")
	check(VolcanicTerrain.point(VolcanicTerrain.VOLCANO).y > 90, "expanded crater towers above the continent")
	check(VolcanicTerrain.LAND_RADIUS.x * VolcanicTerrain.LAND_RADIUS.y > 3 * 119 * 103, "island supports more than three times its previous land area")
	for site in VolcanicLandmarks.SITES:
		var at := island.point(site.x, site.y)
		check(not island.is_water(at) and not VolcanicLava.molten(at), "every future gameplay district has dry safe ground")
		check(MapExploration.BOUNDS.has_point(site), "expanded atlas contains every district")
	check(game.world.map_npcs.has("Sulfur Gardens"), "authored districts appear as discovered map landmarks")
	for crossing in VolcanicRoutes.crossings():
		var at := VolcanicTerrain.point(crossing.at)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 8, at - Vector3.UP, 1))
		check(not hit.is_empty() and hit.position.y > at.y + 0.6, "ash circuit crossing %s has a solid elevated bridge, hit %s" % [at, hit])
		if not hit.is_empty(): check(not VolcanicLava.molten(hit.position), "bridge deck protects walkers from lava")
	check(not ParrotLanding.outdoor(game, castle.king.global_position), "flight cannot skip maze by landing in the royal plaza")
	var total_route := 0
	for deck in 3:
		var floor_node := castle.floors[deck]
		var maze := floor_node.layout
		check(maze.solution.size() >= 45, "each maze has a substantial winding royal route")
		check(maze.dead_ends() >= 5, "each floor has real branches and dead ends")
		total_route += maze.solution.size()
		for cell in maze.solution:
			var at := floor_node.to_global(CastleMazeLayout.center(cell, 0.05))
			var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP, at - Vector3.UP, 1)
			var hit := space.intersect_ray(ray)
			check(not hit.is_empty() and absf(hit.position.y - floor_node.global_position.y) < 0.1, "solution chambers have aligned collision floors")
		for i in range(1, maze.solution.size()):
			var at := floor_node.to_global(CastleMazeLayout.center(maze.solution[i - 1], 0.05))
			var next := floor_node.to_global(CastleMazeLayout.center(maze.solution[i], 0.05))
			check(not actor.test_move(Transform3D(Basis.IDENTITY, at), next - at), "every solution passage fits a real player capsule")
		var cell := Vector2i(0, 0)
		var blocked := floor_node.to_global(CastleMazeLayout.center(cell, 0.05))
		check(actor.test_move(Transform3D(Basis.IDENTITY, blocked), Vector3(-4, 0, 0)), "maze exterior walls physically block walking")
	check(total_route >= 135, "royal journey spans more than 800 metres of corridors")
	var input := WalkInput.new()
	actor.add_child(input)
	actor.command_source = input
	actor.set_physics_process(true)
	game.progression.progress.award_experience(CharacterProgress.threshold(8, true))
	actor.relocate(game.parrot_travel.perches.stations[0].global_position + Vector3(0, 0.05, 2))
	await ticks(3)
	check(game.parrot_travel.start(actor), "jungle parrot boards for the channel crossing")
	input.rise = true
	await ticks(90)
	input.rise = false
	input.move = Vector2.RIGHT
	await ticks(610)
	input.move = Vector2.DOWN
	await ticks(200)
	input.move = Vector2.ZERO
	await ticks(20)
	check(actor.position.x > 225 and actor.position.x < 250 and actor.position.z > 310, "real parrot flight reaches the separate volcanic coast")
	check(game.parrot_travel.request_land(actor), "volcanic beach accepts a safe landing")
	await ticks(320)
	check(not actor.transport_active and actor.is_on_floor() and not game.world.is_water(actor.position), "flight restores ordinary walking on volcanic beach")
	check(game.parrot_travel.available(actor), "landed bird is available for return travel")
	for deck in 3:
		var side := -1.0 if deck % 2 == 0 else 1.0
		var at := castle.to_global(Vector3(0, deck * 8.0 + 0.05, side * 26.3))
		check(actor.relocate(at), "stairway foot is clear")
		await ticks(3)
		input.move = Vector2(0, side)
		await ticks(440)
		input.move = Vector2.ZERO
		await ticks(5)
		check(actor.position.y > castle.position.y + deck * 8 + 7.4, "ordinary walking climbs stairway %d, position %s" % [deck, actor.position])
		check(actor.is_on_floor(), "stairway ascent finishes on a supported landing")
		# The upper return lane connects to the next maze door.
		check(actor.relocate(castle.to_global(Vector3(7, (deck + 1) * 8.0 + 0.05, side * 54))), "upper return lane is clear")
		input.move = Vector2(0, -side)
		await ticks(420)
		input.move = Vector2.ZERO
		await ticks(5)
		check(absf(actor.position.z - (castle.position.z + side * 27)) < 4, "switchback returns to deck %d door, position %s" % [deck + 1, actor.position])
	actor.set_physics_process(false)
	var bridge := castle.to_global(Vector3(0, 0.05, 38))
	check(not VolcanicLava.molten(bridge), "stone entry bridge safely crosses the moat")
	var moat := castle.to_global(Vector3(36, -0.2, 0))
	check(VolcanicLava.molten(moat), "lava moat is hazardous")
	actor.global_position = moat
	game.health.invulnerability = 0
	var health := game.health.current
	var visit: VolcanicVisit = game.get_node("VolcanicVisit")
	visit._physics_process(0.75)
	check(game.health.current < health, "offline lava burns use existing health path")
	var roster := CoopRoster.new()
	game.map.roster = roster
	roster.authority = false
	health = game.health.current
	visit._physics_process(0.75)
	check(game.health.current == health, "guest presentation cannot apply lava damage")
	roster.authority = true
	var member := CoopActor.new()
	member.actor = actor
	member.health = game.health
	roster.party["test"] = member
	visit._physics_process(0.75)
	check(game.health.current < health, "host applies lava damage to party health")
	roster.party.clear()
	game.map.roster = null
	member.free()
	roster.free()
	game.health.restore()
	actor.global_position = castle.king.global_position + Vector3(0, 0.05, -3)
	visit._process(0)
	check(castle.king.greeting.visible, "King greets visitors who reach the plaza")
	var saved := AdventureSnapshot.capture(game, "Lava royal plaza", 0)
	check(SaveStore.valid(saved), "expanded exploration and elevated plaza position save normally")
	var east := VolcanicTerrain.point(VolcanicLandmarks.SITES[3], 0.1)
	actor.global_position = east
	actor.parrot_rest = east
	var eastern_save := AdventureSnapshot.capture(game, "Eastern cove", 0)
	check(SaveStore.valid(eastern_save), "coordinates beyond five hundred save with a parked parrot")
	check(ExplorationProtocol.vector([east.x, east.y, east.z], 3, 1000), "expanded coast remains inside bounded co-op coordinates")
	actor.parrot_rest = Vector3.INF
	actor.global_position = VolcanicTerrain.point(VolcanicTerrain.LANDING, 0.1)
	AdventureSnapshot.restore(game, saved)
	check(actor.position.y > 28 and actor.position.distance_to(castle.king.global_position) < 4, "loading a plaza save retains the reached castle elevation")
	game.map.exploration.reveal(VolcanicTerrain.LANDING)
	var restored := MapExploration.new()
	restored.restore(game.map.exploration.capture())
	check(restored.visited(VolcanicTerrain.LANDING), "volcanic exploration round trips")
	var legacy := PackedByteArray()
	legacy.resize(7589)
	legacy.fill(0)
	var legacy_index := 184 * 171 + 71
	legacy[legacy_index / 8] |= 1 << (legacy_index % 8)
	restored.restore(Marshalls.raw_to_base64(legacy))
	check(restored.visited(Vector2(1, -0.5)), "legacy exploration preserves original world coordinates")
	var previous := PackedByteArray()
	previous.resize(15350)
	previous.fill(0)
	var previous_index := 351 * 307 + 199
	previous[previous_index / 8] |= 1 << (previous_index % 8)
	restored.restore(Marshalls.raw_to_base64(previous))
	check(restored.visited(Vector2(257, 334)), "previous volcanic atlas keeps discoveries in world coordinates")
	check(MapSaveValidation.valid(Marshalls.raw_to_base64(previous)), "previous volcanic checkpoints stay valid")
	restored.reveal(VolcanicLandmarks.SITES[3])
	var newest := MapExploration.new()
	newest.restore(restored.capture())
	check(newest.visited(VolcanicLandmarks.SITES[3]), "eastern cove exploration round trips beyond the former bounds")
	saved.map_exploration = Marshalls.raw_to_base64(legacy)
	check(SaveStore.valid(saved), "old exploration checkpoints remain valid")
	island.atmosphere.elapsed = 10
	check(not island.atmosphere.erupting(), "eruption quiet interval")
	island.atmosphere.elapsed = 43
	check(island.atmosphere.erupting(), "minor eruptions recur periodically")
	castle.present(castle.to_global(Vector3(0, 1, 24)), true)
	check(not castle.floors[1].visible and castle.floors[0].walls[0].scale.y < 0.2, "cutaway shows current maze floor")
	actor.global_position = castle.to_global(Vector3(-24, 0.05, -24))
	check(actor.test_move(actor.global_transform, Vector3(-4, 0, 0)), "cutaway preserves full wall collision")
	game.queue_free()
	await ticks(3)
	print("Volcanic continent: ", "PASS" if failures == 0 else "FAIL", " / royal route chambers: ", total_route)
	quit(1 if failures else 0)
