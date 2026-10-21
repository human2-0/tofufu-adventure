extends SceneTree
## Real capsule traversal of city stairs, roof bridge, streets and joined beaches.

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
	Engine.time_scale = 4.0
	for site in GigalopolisBlocks.ROOFS:
		print("Checking rooftop ", site)
		var at := Vector2(site.x, site.z)
		var start := world.ground_point(site.x + 10, site.z + 20, 0.08)
		actor.relocate(start)
		for tick in 3: await physics_frame
		var top := GigalopolisTerrain.point(at, site.y)
		for target in [Vector3(site.x + 10, top.y, site.z - 1), Vector3(site.x + 10, top.y, site.z - 3), Vector3(site.x + 5, top.y, site.z - 3)]:
			await walk(target)
		check(actor.is_on_floor() and absf(actor.position.y - top.y) < 0.12, "ordinary walking reaches rooftop %s" % site)
		for target in [Vector3(site.x + 10, top.y, site.z - 3), Vector3(site.x + 10, top.y, site.z - 1), start]: await walk(target)
		check(actor.is_on_floor() and absf(actor.position.y - start.y) < 0.2, "stairs descend into their ground approach %s" % site)
	# The two camp terraces also share an elevated route over the street.
	actor.relocate(Vector3(122, 12.05, 132))
	await walk(Vector3(122, 12, 155))
	check(actor.is_on_floor() and absf(actor.position.y - 12) < 0.12, "roof bridge joins both physical decks")
	actor.relocate(world.ground_point(134, 6, 0.05))
	for at: Vector2 in [Vector2(134, 21), Vector2(150, 21), Vector2(150, 60), Vector2(160, 60), Vector2(160, 110), Vector2(160, 178), Vector2(166, 188), Vector2(176, 238), Vector2(192, 280), Vector2(208, 318), Vector2(235, 318)]:
		await walk(world.ground_point(at.x, at.y))
		check(not world.is_water(actor.position), "main city-to-island route stays dry at %s" % at)
	check(actor.is_on_floor(), "city beach physically joins the volcanic landing")
	for at: Vector2 in [Vector2(160, 72), Vector2(202, 110), Vector2(166, 188), Vector2(174, 222), Vector2(206, 310), Vector2(228, 318), Vector2(208, 358)]:
		var expected := world.ground_point(at.x, at.y)
		var hit := actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(expected + Vector3.UP * 0.4, expected - Vector3.UP * 0.4, 1))
		check(not hit.is_empty() and absf(hit.position.y - expected.y) < 0.12, "shared terrain query agrees with city/coast collision %s" % at)
		check(TerrainLocomotion.immersion(expected, world) == 0, "dry promenade has ordinary movement %s" % at)
	for x in range(84, int(GigalopolisTerrain.BOUNDS.end.x) + 1, 4):
		check(absf(GigalopolisTerrain.height_at(Vector2(x, 188)) - VolcanicTerrain.height_at(x, 188)) < 0.02, "entire city/volcanic seam agrees at x=%d" % x)
	check(world.is_water(Vector3(656, -3, 150)) and TerrainLocomotion.immersion(Vector3(656, -3, 150), world) > 0.9, "new city beach retains underwater movement")
	check(not world.is_water(Vector3(150, 0, 6)), "legacy factory square remains dry below sea level")
	for at in GigalopolisBlocks.BLOCKS:
		check(not world.is_water(GigalopolisTerrain.point(at)), "city block entrances sit on dry land %s" % at)
	check(MapTerrainImage._color(world, Vector2(160, 110)) != MapTerrainImage._color(world, Vector2(656, 150)), "map distinguishes city streets and sea")
	for title in GigalopolisBlocks.TITLES: check(world.map_npcs.has(title), "lookout participates in personal map: " + title)
	var old := TerrainLocomotion.saved_position(Vector3(208, -8, 318), world)
	check(old.y >= world.ground_point(208, 318).y, "older channel saves are lifted onto new land")
	var roof := Vector3(190, 14.05, 126)
	check(TerrainLocomotion.saved_position(roof, world).is_equal_approx(roof), "saved rooftop elevation is preserved")
	for kind in ["stone", "metal", "paving", "canvas"]:
		var material := GigalopolisMaterials.surface(kind)
		check(material.albedo_texture != null and material.uv1_world_triplanar, "final city materials use generated textures: " + kind)
		check(material.albedo_texture.get_image().has_mipmaps(), "city textures retain stable distance filtering: " + kind)
	Engine.time_scale = 1.0
	actor.queue_free()
	world.queue_free()
	await process_frame
	print("Gigalopolis traversal: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func walk(target: Vector3) -> void:
	var reached := false
	for tick in 700:
		var offset := Vector2(target.x - actor.position.x, target.z - actor.position.z)
		if offset.length() < 0.2:
			reached = true
			break
		source.move = (offset * 1.8).limit_length()
		await physics_frame
	source.move = Vector2.ZERO
	for tick in 4: await physics_frame
	check(reached and absf(actor.position.y - target.y) < 0.4, "physical city route target %s, actual %s" % [target, actor.position])
