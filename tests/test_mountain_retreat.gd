extends SceneTree
## Graded side trails, real capsule traversal, concealed quest NPC and hut entry.

class TrailInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
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
	var highlands := game.world.dofufu_highlands
	var terrain := highlands.terrain
	var source := TrailInput.new()
	game.player.add_child(source)
	game.player.command_source = source
	await physics_frame
	var maximum_grade: float = 0
	var minimum_sightline: float = 1000
	for route in terrain.paths.routes:
		var first := route[0]
		game.player.position = terrain.point(first.x, first.z, 0.05)
		game.player.velocity = Vector3.ZERO
		for index in route.size() - 1:
			var a := Vector2(route[index].x, route[index].z)
			var b := Vector2(route[index + 1].x, route[index + 1].z)
			var steps := ceili(a.distance_to(b))
			var previous := terrain.point(a.x, a.y)
			for step in range(1, steps + 1):
				var xy := a.lerp(b, float(step) / steps)
				var at := terrain.point(xy.x, xy.y)
				maximum_grade = maxf(maximum_grade, absf(at.y - previous.y) / Vector2(at.x - previous.x, at.z - previous.z).length())
				previous = at
				var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.5, at - Vector3.UP * 1.5, 1)
				var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
				check(not hit.is_empty() and absf(hit.position.y - at.y) < 0.04, "side-trail physical floor matches its rendered triangles")
				for direction in 4:
					var camera := at + game.camera.offset.rotated(Vector3.UP, direction * PI / 2)
					for sight in range(1, 11):
						var sample := (at + Vector3.UP).lerp(camera, sight / 10.0)
						minimum_sightline = minf(minimum_sightline, sample.y - terrain.point(sample.x, sample.z).y)
			for tick in 3600:
				var toward := b - Vector2(game.player.position.x, game.player.position.z)
				if toward.length() < 0.4: break
				source.move = toward.normalized()
				game.player._physics_process(1.0 / 60)
				if tick % 60 == 0: await physics_frame
			check(Vector2(game.player.position.x, game.player.position.z).distance_to(b) < 0.5 and game.player.is_on_floor(), "ordinary walking reaches every side-trail waypoint without jumping; at %s / target %s" % [game.player.position, b])
	check(maximum_grade < 0.65, "side-trail grades stay below the walking slope limit")
	check(minimum_sightline > 0.3, "terrain leaves all four overhead views clear along both paths")
	print("Mountain side trails: max grade %.2f / minimum terrain sightline %.2f m" % [maximum_grade, minimum_sightline])
	game.player.position = terrain.point(-574, 129, 0.05)
	game.player.velocity = Vector3.ZERO
	source.move = Vector2.UP
	for tick in 130:
		game.player._physics_process(1.0 / 60)
		await physics_frame
	check(game.player.position.z < 122 and game.player.is_on_floor(), "hut doorway allows normal walking into its interior")
	game.camera.reset_follow()
	highlands.retreat._process(0)
	check(not highlands.retreat.roofs[0].visible, "overhead roof cutaway reveals the occupied hut without removing collision")
	var hermit := highlands.retreat.hermit
	check(hermit.view_focus == game.player and hermit.art.pixel_size > 0.005, "chunky hybrid character is wired to the local player")
	game.player.position = hermit.position + Vector3.RIGHT * 2
	hermit._process(0)
	check(hermit.greeting.visible and hermit.greeting.visibility_range_end > game.camera.offset.length(), "hermit greets a nearby traveller within the normal overhead camera range")
	game.player.position += Vector3.RIGHT * 20
	hermit._process(0)
	check(not hermit.greeting.visible, "hidden NPC has no distant dialogue beacon")
	for direction in 8:
		hermit.art.present_direction(direction)
		check(hermit.art.current_cell == MountainHybridArt.CELLS[direction] and hermit.art.texture != null, "hybrid has all eight contextual directions from five full views")
	for seed_value in [42, 901, 2061, 8112]:
		var other := DofufuTerrain.new(FarmTerrain.new(seed_value))
		var grade := _seed_grade(other)
		check(grade < 0.65, "procedural seed %d keeps side trails walkable (grade %.2f)" % [seed_value, grade])
		other = null
	game.queue_free()
	for frame in 4: await process_frame
	print("Mountain retreat: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _seed_grade(terrain: DofufuTerrain) -> float:
	var grade: float = 0
	for route in terrain.paths.routes:
		for index in route.size() - 1:
			var a := Vector2(route[index].x, route[index].z)
			var b := Vector2(route[index + 1].x, route[index + 1].z)
			var steps := ceili(a.distance_to(b))
			var previous := terrain.point(a.x, a.y)
			for step in range(1, steps + 1):
				var at := a.lerp(b, float(step) / steps)
				var point := terrain.point(at.x, at.y)
				grade = maxf(grade, absf(point.y - previous.y) / Vector2(point.x - previous.x, point.z - previous.z).length())
				previous = point
	return grade
