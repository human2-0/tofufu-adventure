extends SceneTree
## Sustained real-collision seabed traversal, motor drag, seams and presentation expiry.

class OceanInput extends PlayerCommandSource:
	var direction := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = direction
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
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var input := OceanInput.new()
	game.player.add_child(input)
	game.player.command_source = input
	for tick in 3: await physics_frame
	for x in [-100.0, 0.0, 80.0]:
		check(is_equal_approx(OceanTerrain.height_at(x, -84, game.world.terrain), game.world.terrain.height_at(x, -84)), "meadow seam uses the actual farm edge")
		check(game.world.ocean.point(x, -94 - WorldContours.coast(x, game.world.terrain.noise.seed)).y > OceanTerrain.WATER_LEVEL + 0.3, "beach has dry sand above the swells")
		check(is_equal_approx(game.world.ocean.point(x, -220).y, game.world.frost.point(x, -220).y), "north exit joins the frost floor")
		check(game.world.ocean.point(x, -220).y > OceanTerrain.WATER_LEVEL, "north shore rises out of the water")
	for x in [-125.0, 125.0]:
		var start := Transform3D(Basis.IDENTITY, game.world.ground_point(x, -99, 0.1))
		check(game.player.test_move(start, Vector3(0, 0, 18)), "rocky headlands block walking off the beach wings")
	for at in [Vector2(0, -138), Vector2(85, -151), Vector2(-101, -182)]:
		var floor_at := game.world.ocean.point(at.x, at.y)
		check(not TerrainLocomotion.fallen(floor_at, game.world), "authored seabed is never classified as a fall")
		check(TerrainLocomotion.fallen(Vector3(floor_at.x, minf(-6, floor_at.y - 8), floor_at.z), game.world), "falling through the seabed still recovers")
		var query := PhysicsRayQueryParameters3D.create(floor_at + Vector3.UP * 3, floor_at + Vector3.DOWN, 1)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.y - floor_at.y) < 0.2, "reef collision matches its terrain query")
	check(game.player.relocate(game.world.ground_point(0, -130, 0.1)), "place player on the underwater trail")
	var start_health := game.health.current
	Engine.time_scale = 6.0
	input.direction = Vector2.UP
	for tick in 150: await physics_frame
	input.direction = Vector2.ZERO
	for tick in 300: await physics_frame
	check(game.player.position.z < -145 and game.player.position.y < -3, "walk and remain underwater for forty-five simulated seconds")
	check(game.health.current == start_health and game.player.is_on_floor(), "sustained seabed walking neither respawns nor damages the actor")
	check(game.player.motor.immersion == 1.0 and game.player.surface_speed < 0.5, "deep water has dense resistance")
	input.direction = Vector2.DOWN
	for tick in 150: await physics_frame
	check(game.player.position.z > -138, "underwater route can be walked back")
	for tick in 180: await physics_frame
	input.direction = Vector2.ZERO
	for tick in 5: await physics_frame
	check(game.player.position.z > -103 and game.player.position.y > OceanTerrain.WATER_LEVEL and game.player.motor.immersion == 0.0, "walk up the sandy slope and leave the ocean without teleporting")
	check(game.health.current == start_health, "shore traversal preserves health")
	game.player.relocate(game.world.ground_point(0, -140, 0.1))
	for tick in 5: await physics_frame
	Engine.time_scale = 1.0
	input.direction = Vector2.ZERO
	var life := game.get_node("WorldLife/OceanExperience") as OceanExperience
	life.bubbles.breathe(game.player.position, Vector2.DOWN)
	check(life.bubbles._ages.count(8.0) >= 5, "submerged actor emits a breath of bubbles")
	life.bubbles._process(10.0)
	check(life.bubbles._ages.count(0.0) == OceanBubbles.CAPACITY, "bubbles expire at the surface or age limit")
	for i in OceanBubbles.CAPACITY:
		check(life.bubbles._sizes[i] == 0.0, "expired bubble slots are hidden")
	check(game.camera.environment == life._underwater and life.drift.active, "submersion adds depth haze and suspended water particles")
	game.player.position = game.world.ground_point(0, -94, 0.1)
	TerrainLocomotion.apply(game.player, game.world)
	life._process(1.0)
	check(game.player.motor.immersion == 0 and game.player.surface_speed == 1.0 and game.player.motor.surface_grip == 1.0, "leaving the water fully restores dry movement")
	check(game.camera.environment == null and not life.drift.active, "leaving the water restores the previous camera environment")
	var saved := AdventureSnapshot.capture(game, "Ocean shore", 0)
	saved.position = [0, -4.8, -94]
	AdventureSnapshot.restore(game, saved)
	check(game.player.position.y > OceanTerrain.WATER_LEVEL and absf(game.player.position.z + 94) < 1.0, "legacy ocean saves load safely on the new beach")
	game.player.relocate(game.world.ground_point(0, -140, 0.1))
	saved = AdventureSnapshot.capture(game, "Ocean reef", 0)
	game.player.relocate(game.world.ground_point(0, -94, 0.1))
	AdventureSnapshot.restore(game, saved)
	check(game.player.position.z < -139 and game.player.position.y < -3, "saving and loading retains safe deep-ocean exploration")
	var animals := game.world.ocean.wildlife
	var before := animals.creatures[0].position
	animals._process(0.5)
	check(animals.creatures.size() == 60 and animals.creatures[0].position != before, "bounded marine wildlife actually swims")
	_rules()
	game.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	print("Ocean experience: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _rules() -> void:
	var tuning := PlayerTuning.new()
	var dry := PlayerMotor.new(tuning)
	var wet := PlayerMotor.new(tuning)
	wet.immersion = 1.0
	var command := PlayerCommand.new()
	var normal := dry.step(command, Vector3.ZERO, false, 0.1)
	var underwater := wet.step(command, Vector3.ZERO, false, 0.1)
	check(absf(underwater.y) < absf(normal.y) * 0.35, "water reduces gravity and damps vertical speed")
	command.jump_pressed = true
	var launched := wet.step(command, Vector3.ZERO, true, 1.0 / 60)
	check(launched.y > 5 and launched.y < tuning.jump_velocity, "buoyant jump remains deliberate and bounded")
	wet.is_dashing = true
	wet.dash_remaining = 0.15
	wet._dash_direction = Vector3.RIGHT
	check(wet.step(PlayerCommand.new(), Vector3.ZERO, true, 0.01).x < tuning.dash_speed * 0.5, "dashing also respects dense water")
	wet.dash_remaining = 0.0
	check(wet.step(PlayerCommand.new(), Vector3.ZERO, true, 0.01).x < 3.0, "dash recovery cannot restore dry momentum underwater")
	check(dry.immersion == 0, "water state stays per actor")
