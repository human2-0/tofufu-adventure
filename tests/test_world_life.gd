extends SceneTree
## Wildlife is cosmetic, bounded and reactive; movement feedback works locally.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var flight := BirdFlight.new()
	flight.at = Vector3(0, 2, 0)
	flight.launch(Vector3(10, 3, 5), 2.0, 4.0)
	flight.step(1.0)
	check(flight.airborne and flight.at.y > 6, "bird lifts off above terrain on a rounded arc")
	flight.step(2.0)
	check(not flight.airborne and flight.at == Vector3(10, 3, 5), "bird lands at exact terrain height without overshoot")
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	await physics_frame
	var life := game.get_node("WorldLife") as WorldLife
	check(life.birds.birds.size() == MeadowBirds.COUNT, "sixteen birds are composed into the actual adventure")
	for state in life.birds.flights:
		check(life._habitat(state.at), "birds start outside water, buildings and map edges")
	var first := life.birds.flights[0]
	first.airborne = false
	first.resting = 8.0
	var at := first.at
	life.birds.scatter(at, 2.0)
	check(first.airborne and first.destination.distance_to(at) > 3.0, "a nearby disturbance scatters a resting bird")
	var count := life.birds.get_child_count()
	life.birds.observers.clear()
	for tick in 1500:
		life.birds._process(0.1)
	check(life.birds.get_child_count() == count, "long wildlife simulation never allocates additional birds")
	for state in life.birds.flights:
		check(state.at.is_finite() and life._habitat(state.destination), "flights retain finite positions and safe landing destinations")
	for burst in 100:
		life.particles.burst(Vector3.ZERO, Vector3.ZERO, 20, burst % 2 == 0)
		life.particles._process(0.1)
	check(life.particles.multimesh.instance_count == MotionParticles.CAPACITY, "effects reuse a fixed particle pool")
	life.particles._process(1.0)
	for i in MotionParticles.CAPACITY:
		check(life.particles._ages[i] == 0.0, "particles expire within their bounded lifetime")
	var feet := game.player.get_node("PlayerFootsteps") as PlayerFootsteps
	var steps: Array[int] = [0]
	feet.stepped.connect(func(_at: Vector3, _speed: float) -> void: steps[0] += 1)
	game.player.velocity = Vector3(4, 0, 0)
	feet.present_grounded(true)
	feet._until_step = 0.0
	feet._physics_process(0.1)
	check(steps[0] == 1, "local player emits footstep feedback")
	feet.present_dashing(true)
	feet._until_step = 0.0
	feet._physics_process(0.1)
	check(steps[0] == 1, "replicated dash suppresses ordinary walking steps")
	feet.present_dashing(false)
	game.player.relocate(game.world.seed_bank.global_position + Vector3(0, 0.5, -3))
	check(not life._outdoor(), "barn interior suppresses outdoor audio and particles")
	life.audio.enabled = false
	life.audio.present(5.0, 1.0, true, 0.0)
	check(life.audio._rain.volume_db <= -79 and life.audio._river.volume_db <= -79, "indoor ambience fades out")
	first = null
	flight = null
	game.queue_free()
	await process_frame
	print("World life tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
