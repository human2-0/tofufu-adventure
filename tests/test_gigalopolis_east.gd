extends SceneTree
## East-west walking, open halls, distinct physical roofs and three public lookouts.

class WalkInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		return command

var failures: int = 0
var world: Meadow
var actor: Player
var source := WalkInput.new()

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	world = Meadow.new()
	root.add_child(world)
	actor = load("res://game/player/player.tscn").instantiate()
	actor.command_source = source
	actor.add_child(source)
	root.add_child(actor)
	for tick in 3: await physics_frame
	Engine.time_scale = 4
	check(GigalopolisTerrain.BOUNDS.end.x >= VolcanicTerrain.CENTER.x + VolcanicTerrain.LAND_RADIUS.x - 20, "city extends east to the volcanic island's width")
	check(GigalopolisTerrain.BOUNDS.size.x > 3 * 172, "east-west city span more than triples the previous core")
	actor.relocate(world.ground_point(238, 6, 0.05))
	for x in [260.0, 324.0, 388.0, 452.0, 516.0, 580.0, 636.0]:
		await walk(world.ground_point(x, 6))
		check(not world.is_water(actor.position) and actor.is_on_floor(), "main avenue remains dry and continuous at %s" % x)
	await walk(world.ground_point(636, 158))
	check(actor.position.x > 630, "real capsule reaches and explores the far eastern shore")
	for site in GigalopolisEast.LOOKOUTS:
		var origin: Vector2 = site.at
		var start_at: Vector2 = origin + site.start
		var start := world.ground_point(start_at.x, start_at.y, 0.05)
		var top: float = GigalopolisTerrain.point(origin).y + float(site.height)
		actor.relocate(start)
		for tick in 3: await physics_frame
		for local: Vector2 in [site.finish, site.landing, site.deck]: await walk(Vector3(origin.x + local.x, top, origin.y + local.y))
		check(actor.is_on_floor() and absf(actor.position.y - top) < 0.12, "ordinary walking reaches " + str(site.title))
		await explore_roof(origin, top, int(site.height))
		for local: Vector2 in [site.landing, site.finish]: await walk(Vector3(origin.x + local.x, top, origin.y + local.y))
		await walk(start)
		check(actor.is_on_floor(), "stair descent rejoins the avenue: " + str(site.title))
		check(world.map_npcs.has(site.title), "public landmark has a personal map marker")
	# The market is an actual pass-through hall beneath its public roof.
	actor.relocate(world.ground_point(292, 28, 0.05))
	await walk(world.ground_point(292, 72))
	# The U-shaped hall leaves its courtyard entrance open; the cistern is off-axis.
	actor.relocate(world.ground_point(424, 70, 0.05))
	await walk(world.ground_point(424, 48))
	# Under the tank there is clear, collision-backed walking space between supports.
	actor.relocate(world.ground_point(356, 120, 0.05))
	await walk(world.ground_point(356, 144))
	var space := actor.get_world_3d().direct_space_state
	var market_floor := world.ground_point(292, 50)
	var skylight := space.intersect_ray(PhysicsRayQueryParameters3D.create(market_floor + Vector3.UP * 30, market_floor + Vector3.UP * 2, 1))
	check(skylight.is_empty(), "market skylight keeps ground-level walkers visible from overhead")
	for site: Vector3 in [Vector3(356, 11, 50), Vector3(489.5, 8, 50), Vector3(296, 12, -24)]:
		var base := world.ground_point(site.x, site.z)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(base + Vector3.UP * 35, base, 1))
		check(not hit.is_empty() and hit.position.y > base.y + site.y, "vaulted, sawtooth and gabled roof geometry has matching physical collision %s" % site)
	for at: Vector2 in [Vector2(260, 6), Vector2(324, 110), Vector2(516, 158), Vector2(636, 96), Vector2(450, 188), Vector2(610, 196)]:
		var point := world.ground_point(at.x, at.y)
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.4, point - Vector3.UP * 0.4, 1))
		check(not hit.is_empty() and absf(hit.position.y - point.y) < 0.12, "eastern land/shore queries agree with visible collision %s" % at)
		check(MapExploration.BOUNDS.has_point(at), "new districts fit the existing saved exploration bounds")
	check(MapTerrainImage._color(world, Vector2(600, 110)) != Color("163b52"), "atlas presents eastern streets as land")
	check(TerrainLocomotion.saved_position(Vector3(600, -8, 110), world).y >= world.ground_point(600, 110).y, "older offshore saves are lifted onto the eastern wards")
	for kind in ["roof", "glass", "brick", "frieze"]:
		var material := GigalopolisMaterials.surface(kind)
		check(material.albedo_texture != null and material.albedo_texture.get_image().has_mipmaps(), "new structural families use generated distance-filtered surfaces: " + kind)
	Engine.time_scale = 1
	actor.queue_free()
	world.queue_free()
	for tick in 3: await process_frame
	print("Gigalopolis eastern quarters: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func explore_roof(origin: Vector2, top: float, height: int) -> void:
	# Visit the actual camp and telescope approach, including the bridges around
	# the market skylight, then retrace a safe route back to the stair landing.
	var routes := {
		8: [Vector2(16, -13), Vector2(-14, -13), Vector2(-14, -3), Vector2(-14, -13), Vector2(16, -13), Vector2(16, 5), Vector2(13, 7), Vector2(16, 5), Vector2(16, -10)],
		12: [Vector2(14, -16.5), Vector2(-6, -16.5), Vector2(-6, -12), Vector2(-6, -16.5), Vector2(12, -16.5), Vector2(12, -10), Vector2(17, -14)],
		22: [Vector2(7, -3), Vector2(7, 1), Vector2(-3, 1), Vector2(7, 1), Vector2(7, 6), Vector2(7, -5)]
	}
	for local: Vector2 in routes[height]:
		await walk(Vector3(origin.x + local.x, top, origin.y + local.y))
		check(actor.is_on_floor(), "camp and recon route retains physical support")

func walk(target: Vector3) -> void:
	var reached := false
	for tick in 900:
		var offset := Vector2(target.x - actor.position.x, target.z - actor.position.z)
		if offset.length() < 0.2:
			reached = true
			break
		source.move = (offset * 1.8).limit_length()
		await physics_frame
	source.move = Vector2.ZERO
	for tick in 4: await physics_frame
	check(reached and absf(actor.position.y - target.y) < 0.4, "east city target %s, actual capsule %s" % [target, actor.position])
