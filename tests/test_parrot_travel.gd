extends SceneTree
## Real free-flight steering, hover, collision, landing/remount and safe persistence.

class FlightInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	var rise: bool = false
	var descend: bool = false
	var blocked: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.jump_held = rise
		command.dash_held = descend
		command.cancel_actions = blocked
		return command

var failures: int = 0
var air_steps: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for tick in count: await physics_frame

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	await ticks(3)
	var travel := game.parrot_travel
	check(not travel.start(game.player), "boarding requires an actual nearby parrot")
	game.player.relocate(travel.perches.stations[1].global_position + Vector3(0, 0.1, 3))
	await ticks(3)
	game.world_items._process(0)
	var origin := game.player.position
	var key := InputEventAction.new()
	key.action = "pickup_weapon"
	key.pressed = true
	root.push_input(key)
	key.pressed = false
	root.push_input(key)
	check(game.player.transport_active and game.shooting_view.local_input.enabled, "interaction mounts immediately and keeps steering enabled")
	var input := FlightInput.new()
	game.player.add_child(input)
	game.player.command_source = input
	var feet := game.player.get_node("PlayerFootsteps") as PlayerFootsteps
	feet.stepped.connect(func(_at: Vector3, _speed: float) -> void:
		if game.player.transport_active: air_steps += 1)
	await ticks(70)
	check(game.player.position.y > origin.y + 5, "mount takes off and hovers above the ground")
	var before := game.player.position
	input.move = Vector2.RIGHT
	await ticks(35)
	check(game.player.position.x > before.x + 8, "movement commands freely steer the mount faster than walking")
	input.move = Vector2.UP
	await ticks(40)
	check(game.player.position.z < before.z - 5, "rider can change course without a destination route")
	input.move = Vector2.ZERO
	input.rise = true
	var height := game.player.position.y
	await ticks(30)
	check(game.player.position.y > height + 2, "jump binding raises altitude")
	input.rise = false
	input.descend = true
	height = game.player.position.y
	await ticks(40)
	check(game.player.position.y < height - 2, "dash binding lowers altitude")
	input.descend = false
	input.blocked = true
	before = game.player.position
	await ticks(12)
	check(game.player.position.is_equal_approx(before), "menus and blocked commands hover in place")
	input.blocked = false
	check(air_steps == 0 and not feet.grounded(), "flight emits no footstep or ground dust events")
	var saved := AdventureSnapshot.capture(game, "Free flight", 0)
	check(SaveStore.valid(saved) and Vector3(saved.position[0], saved.position[1], saved.position[2]).is_equal_approx(origin), "saving in flight retains a safe grounded departure")
	# Test an actual tall collider in the rider's path.
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 70, 12)
	shape.shape = box
	wall.add_child(shape)
	game.add_child(wall)
	wall.position = game.player.position + Vector3(6, 0, 0)
	var wall_x := wall.position.x
	input.move = Vector2.RIGHT
	await ticks(35)
	check(game.player.position.x < wall_x - 0.5, "free flight collides with solid world obstacles")
	input.move = Vector2.ZERO
	wall.queue_free()
	await ticks(5)
	check(travel.request_land(game.player), "rider can land away from a station on dry ground")
	await ticks(130)
	check(not game.player.transport_active and game.player.is_on_floor(), "landing restores ordinary grounded movement")
	check(game.player.parrot_rest.is_finite() and travel.available(game.player), "parrot stays at the landing point and can be remounted")
	await process_frame
	check(travel.mounts.parked.has(game.player), "landed parrot remains visible")
	var parked := AdventureSnapshot.capture(game, "Parked", 0)
	check(SaveStore.valid(parked) and parked.parrot_rest.size() == 3, "parked parrot persists in solo saves")
	var corrupt: Dictionary = parked.duplicate(true)
	corrupt.parrot_rest = [0, INF, 0]
	check(not SaveStore.valid(corrupt), "invalid parked positions are rejected")
	check(travel.start(game.player), "mount can take off again from an arbitrary landing point")
	await ticks(10)
	game._respawn()
	await ticks(3)
	check(not game.player.transport_active and travel.flights.is_empty(), "respawn cancels free flight without moving the player back")
	game.player.relocate(travel.perches.stations[3].global_position + Vector3(0, 0.1, 3))
	check(travel.start(game.player), "shore perch supports free flight")
	input.move = Vector2.UP
	await ticks(110)
	input.move = Vector2.ZERO
	await ticks(20)
	check(game.player.position.z < OceanTerrain.NORTH_START and game.player.position.y > OceanTerrain.WATER_LEVEL + 5, "flight crosses the ocean above its water surface")
	check(not travel.request_land(game.player) and game.player.transport_active, "ocean landing is rejected without dropping the rider")
	game._respawn()
	await ticks(3)
	game.player.parrot_rest = Vector3(1, 0.05, 0)
	check(travel.start(game.player), "parked parrot near respawn can be ridden")
	check(game.player.position.distance_to(Vector3.ZERO) < 4, "nearby respawn scenario stays inside teleport-distance detection")
	game._respawn()
	check(not game.player.transport_active and travel.flights.is_empty(), "nearby respawn explicitly cancels flight")
	# Area gates are intentionally open while testing, including airborne access.
	game.progression.progress.restore({})
	game.player.relocate(game.world.ground_point(0, JungleTerrain.SOUTH_START - 4, 0.1))
	game.player.parrot_rest = game.player.position
	check(travel.start(game.player), "level-one rider can board at the southern pass")
	input.move = Vector2.DOWN
	await ticks(60)
	input.move = Vector2.ZERO
	check(game.progression.progress.level() == 1 and game.player.position.z > JungleTerrain.SOUTH_START + 5, "level-one flight crosses into jungle without a progression clamp")
	game.queue_free()
	await process_frame
	print("Parrot free flight: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
