extends SceneTree
## Fixed-map recovery, swept contacts, actor isolation and actual meadow wiring.

class WalkInput extends PlayerCommandSource:
	var movement := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = movement
		command.aim = Vector2.RIGHT
		return command

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

func _cell(point: Vector2) -> Vector2i:
	return Vector2i(((point - GrassImprint.ORIGIN) / GrassImprint.CELL).floor())

func _run() -> void:
	var field := GrassImprint.new()
	check(field.image.get_size() == Vector2i(304, 256), "deformation memory has a fixed footprint")
	field.press(Vector2(-12, -16), Vector2(-9, -16))
	var middle := _cell(Vector2(-10.5, -16))
	check(field.bends.has(middle), "fast grounded motion leaves a continuous swept trail")
	var initial := field.bends[middle].length()
	field.recover(1.0)
	check(field.bends[middle].length() < initial and field.bends[middle].length() > 0.1, "trail relaxes gradually and remains after departure")
	field.recover(5.0)
	check(field.bends.is_empty(), "abandoned grass fully recovers")
	check(field.image.get_pixelv(middle).is_equal_approx(GrassImprint.NEUTRAL), "recovery resets the GPU map to exactly neutral")
	field.press(Vector2(-30, -16), Vector2(30, -16))
	check(not field.bends.has(_cell(Vector2(0, -16))), "teleportation cannot flatten the space between endpoints")
	field.press(Vector2(-200, -200), Vector2(-201, -201))
	check(field.bends.size() < 40, "off-map contacts cannot grow the field")
	var other := GrassImprint.new()
	check(other.bends.is_empty() and other.texture != field.texture, "each world owns independent deformation")
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	await physics_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var source := WalkInput.new()
	game.player.add_child(source)
	game.player.command_source = source
	game.player.relocate(game.world.ground_point(-5, -16) + Vector3.UP * 0.1)
	for tick in 20: await physics_frame
	var start := game.player.position
	source.movement = Vector2.RIGHT
	for tick in 40: await physics_frame
	source.movement = Vector2.ZERO
	var end := game.player.position
	var midpoint := Vector2((start.x + end.x) * 0.5, (start.z + end.z) * 0.5)
	check(end.distance_to(start) > 1.0, "real actor walks across the collision-backed meadow")
	check(game.world.grass_imprint.bends.has(_cell(midpoint)), "real walk leaves a surviving imprint behind the actor")
	game.player.set_physics_process(false)
	var response := (game.get_node("WorldLife") as WorldLife).grass
	response.set_physics_process(false)
	var grass := game.world.get_node("WildGrass")
	var blades: int = 0
	for patch: MultiMeshInstance3D in grass.get_children():
		blades += patch.multimesh.instance_count * MeadowGrass.BLADES_PER_TUFT
		check(patch.visibility_range_end == 48.0 and patch.extra_cull_margin >= 0.6, "patches cull beyond view with enough room for bending")
		check(patch.multimesh.mesh.surface_get_array_len(0) == 7 * MeadowGrass.BLADES_PER_TUFT, "segmented narrow blades can curve while their roots stay fixed")
	check(blades > 60000 and blades < 290000, "meadow has dense bounded seeded coverage")
	print("Grass coverage: ", blades, " blades in ", grass.get_child_count(), " patches")
	var at := game.world.ground_point(-12, -16)
	game.player.position = at
	var feet := game.player.get_node("PlayerFootsteps") as PlayerFootsteps
	feet.present_grounded(true)
	response._physics_process(0.05)
	check(game.world.grass_imprint.bends.has(_cell(Vector2(at.x, at.z))), "grounded actor actually deforms the material's bound map")
	check(game.world.grass_material.get_shader_parameter("bend_map") == game.world.grass_imprint.texture, "renderer reads this world's deformation map")
	feet.present_grounded(false)
	game.player.position = game.world.ground_point(-8, -16) + Vector3.UP * 2
	response._physics_process(0.05)
	check(not game.world.grass_imprint.bends.has(_cell(Vector2(-8, -16))), "airborne actors leave no new imprint")
	feet.present_grounded(true)
	game.player.transport_active = true
	game.player.position = game.world.ground_point(-7, -16)
	response._physics_process(0.05)
	check(not game.world.grass_imprint.bends.has(_cell(Vector2(-7, -16))), "mounted travel does not press grass")
	game.player.transport_active = false
	var peer: Player = load("res://game/player/player.tscn").instantiate()
	peer.command_source = RemotePlayerInput.new()
	peer.add_child(peer.command_source)
	game.add_child(peer)
	peer.set_physics_process(false)
	peer.position = game.world.ground_point(-15, -16)
	(peer.get_node("PlayerFootsteps") as PlayerFootsteps).present_grounded(true)
	game.player.placement_peers.append(peer)
	response._physics_process(0.05)
	check(game.world.grass_imprint.bends.has(_cell(Vector2(-15, -16))), "grounded co-op replica contributes a local cosmetic imprint")
	game.player.placement_peers.erase(peer)
	peer.queue_free()
	game.player.hide()
	response._physics_process(6.0)
	check(game.world.grass_imprint.bends.is_empty(), "hidden/departed actors stop pressing and grass recovers")
	game.wind.strength = 0.8
	for node in game.get_children():
		if node is WeatherFlow:
			node._physics_process(0.0)
			node._changed(WeatherCycle.Condition.RAIN)
	check(is_equal_approx(game.world.grass_material.get_shader_parameter("wind_strength"), 0.8), "weather still drives wind independently of trail recovery")
	check(is_equal_approx(game.world.grass_material.get_shader_parameter("wetness"), 1.0), "rain dampens grass without replacing wind or contact deformation")
	field = null
	other = null
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("Grass tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
