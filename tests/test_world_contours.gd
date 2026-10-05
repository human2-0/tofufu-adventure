extends SceneTree
## Seed variation, continuous biome gradients and collision-backed emergent islands.

class AtollInput extends PlayerCommandSource:
	var direction := Vector2.RIGHT
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = direction
		return command

var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var farm := FarmTerrain.new(1847)
	var alternate := FarmTerrain.new(8742)
	var spread: Array[float] = []
	var differs := false
	for x in range(-100, 101, 10):
		var a := WorldContours.coast(x, farm.noise.seed)
		spread.append(a)
		check(a == WorldContours.coast(x, farm.noise.seed), "rebuilding a seed reproduces its shoreline")
		differs = differs or absf(a - WorldContours.coast(x, alternate.noise.seed)) > 2.0
	check(spread.max() - spread.min() > 8 and differs, "shoreline meanders substantially and changes with the seed")
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.set_physics_process(false)
	for tick in 3: await physics_frame
	for x in [-65.0, -30.0, 0.0, 30.0, 65.0]:
		check(is_equal_approx(game.world.terrain.height_at(x, -84), game.world.ocean.point(x, -84).y), "northern seam shares the actual meadow elevation")
		check(is_equal_approx(game.world.terrain.height_at(x, 84), game.world.desert.point(x, 84).y), "southern seam shares the actual meadow elevation")
		check(is_equal_approx(game.world.desert.point(x, 216).y, game.world.jungle.point(x, 216).y), "dunes join jungle without a height discontinuity")
		check(is_equal_approx(game.world.ocean.point(x, -220).y, game.world.frost.point(x, -220).y), "shore joins snow without a height discontinuity")
		for seam in [-220.0, -84.0, 84.0, 216.0]:
			var a := game.world.ground_point(x, seam - 0.04).y
			var b := game.world.ground_point(x, seam + 0.04).y
			check(absf(a - b) < 0.15, "height remains continuous on both sides of each biome crossing")
	var ocean: OceanWorld = game.world.ocean
	check(ocean.point(80, -169).y > OceanTerrain.WATER_LEVEL + 1.0, "crescent has a dry, elevated lookout")
	check(ocean.point(66, -157).y < OceanTerrain.WATER_LEVEL and ocean.point(36, -153).y < OceanTerrain.WATER_LEVEL, "lagoon connects to the sea through its western inlet")
	for isle in OceanIslands.ISLETS:
		check(ocean.point(isle.x, isle.y).y > OceanTerrain.WATER_LEVEL, "satellite islets emerge from the ocean")
	check(game.world.map_npcs.has("Tideglass Atoll"), "new island lookout participates in explored map markers")
	# Isolate collision ground so a scenery rock cannot conceal a mismatched mesh.
	var floor_world := Node3D.new()
	var floor_view := SubViewport.new()
	floor_view.own_world_3d = true
	root.add_child(floor_view)
	floor_view.add_child(floor_world)
	OceanTerrain.build(floor_world, farm)
	for tick in 2: await physics_frame
	for at in [Vector2(66, -177), Vector2(79, -169), Vector2(66, -157), Vector2(-86, -134)]:
		var desired := ocean.point(at.x, at.y)
		var query := PhysicsRayQueryParameters3D.create(desired + Vector3.UP * 0.4, desired + Vector3.DOWN * 0.4, 1)
		var hit := floor_world.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.y - desired.y) < 0.2, "island and lagoon collision follow their rendered terrain")
	var before := BiomePalette.color_at(Vector2(28, 83.99), 1, 1847)
	var after := BiomePalette.color_at(Vector2(28, 84.01), 1, 1847)
	check(Vector3(before.r - after.r, before.g - after.g, before.b - after.b).length() < 0.005, "ground colours blend continuously across the meadow/desert seam")
	var atoll_map := MapTerrainImage._color(game.world, Vector2(80, -169))
	var lagoon_map := MapTerrainImage._color(game.world, Vector2(66, -157))
	check(atoll_map != lagoon_map, "map distinguishes dry atoll terrain from its lagoon")
	var first_fish := ocean.wildlife.creatures[0].position
	ocean.wildlife._process(2.0)
	check(not ocean.wildlife.visible and ocean.wildlife.creatures[0].position == first_fish, "distant wildlife pauses its cosmetic updates")
	for creature in ocean.wildlife.creatures:
		var at := creature.position
		check(at.y > ocean.point(at.x, at.z).y and at.y < OceanTerrain.WATER_LEVEL, "wildlife receives valid underwater positions before visiting the reef")
	ocean.wildlife.focus = Vector3(0, 0, -150)
	for step in 16:
		ocean.wildlife._process(2.0)
		for creature in ocean.wildlife.creatures:
			var at := creature.position
			check(at.y > ocean.point(at.x, at.z).y and at.y < OceanTerrain.WATER_LEVEL, "reef and lagoon wildlife stay in water above their terrain")
	await _walk_atoll(game)
	floor_view.queue_free()
	game.queue_free()
	await process_frame
	print("World contours: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _walk_atoll(game: AdventureGame) -> void:
	var input := AtollInput.new()
	game.player.add_child(input)
	game.player.command_source = input
	game.player.relocate(game.world.ground_point(30, -153, 0.1))
	game.player.set_physics_process(true)
	var health := game.health.current
	Engine.time_scale = 6.0
	for tick in 420:
		await physics_frame
		if game.player.position.x >= 80: break
	input.direction = Vector2.ZERO
	for tick in 5: await physics_frame
	Engine.time_scale = 1.0
	check(game.player.position.x >= 80 and game.player.position.z < -150 and game.player.position.y > OceanTerrain.WATER_LEVEL, "walk through the tidal inlet and climb onto the atoll without teleporting")
	check(game.health.current == health and game.player.is_on_floor(), "lagoon traversal preserves health and stable floor contact")
	game.player.set_physics_process(false)
