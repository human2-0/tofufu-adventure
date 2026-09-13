extends SceneTree
## Real CharacterBody3D sweeps: all actor pairs, dash, and occupied spawns.

class TestInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	var dash: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.aim = move
		command.dash_direction = move
		command.dash_pressed = dash
		dash = false
		return command

var failures: int = 0
var world: Node3D
var player: Player
var source: TestInput

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _player(at: Vector3) -> Player:
	var actor: Player = load("res://game/player/player.tscn").instantiate()
	var input := TestInput.new()
	actor.add_child(input)
	actor.command_source = input
	actor.position = at
	world.add_child(actor)
	actor.set_physics_process(false)
	return actor

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	player = _player(Vector3(-2, 0.05, 0))
	source = player.command_source
	var other := _player(Vector3(0, 0.05, 0))
	player.placement_peers = [player, other]
	await physics_frame
	source.move = Vector2.RIGHT
	await walk(50)
	check(player.position.x < -0.79, "walking player stops at another player")
	player.position = Vector3(-2, 0.05, 0)
	player.velocity = Vector3.ZERO
	source.dash = true
	await walk(20)
	check(player.position.x < -0.79, "dash cannot tunnel through player")
	check(player.relocate(other.position), "occupied player respawn finds space")
	check(player.position.distance_to(other.position) >= 0.8, "respawn positions do not overlap")
	# Multiple placements in one tick must account for earlier arrivals.
	var third := _player(Vector3(8, 0.05, 0))
	third.placement_peers = player.placement_peers
	third.placement_peers.append(third)
	check(third.relocate(other.position), "third player can respawn in same tick")
	check(third.position.distance_to(player.position) >= 0.8 and third.position.distance_to(other.position) >= 0.8, "same-tick respawns remain separated")
	other.position = Vector3(8, 0.05, 0)
	third.position = Vector3(10, 0.05, 0)
	var snail := TrainingMob.new()
	snail.position = Vector3(0, 0.1, 0)
	world.add_child(snail)
	player.placement_peers.append(snail)
	snail.spawn_clearance = func(shape: CapsuleShape3D, at: Transform3D) -> bool:
		return not PlayerPlacement.overlaps_actors(snail, shape, at, player.placement_peers)
	snail.set_physics_process(false)
	player.position = Vector3(-2, 0.05, 0)
	player.velocity = Vector3.ZERO
	await walk(50)
	check(player.position.x < -0.84, "player stops at snail capsule")
	player.position = Vector3(-2, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.motor.cooldown_remaining = 0
	source.dash = true
	await walk(20)
	check(player.position.x < -0.84, "dash stops at snail capsule")
	var second_snail := TrainingMob.new()
	second_snail.position = Vector3(2, 0.1, 0)
	world.add_child(second_snail)
	second_snail.set_physics_process(false)
	await physics_frame
	for i in 50:
		second_snail.velocity = Vector3(-4, 0, 0)
		second_snail.move_and_slide()
		await physics_frame
	check(second_snail.position.x > 0.89, "snails cannot pass through each other")
	player.position = Vector3(-1, 0.05, 0)
	for i in 30:
		snail.velocity = Vector3(-4, 0, 0)
		snail.move_and_slide()
		await physics_frame
	check(snail.position.x - player.position.x >= 0.84, "moving snail stops at stationary player")
	snail.target.damage(999)
	player.position = snail._home
	snail._physics_process(23)
	check(not snail.visible and snail.collision_layer == 0, "snail waits for a player arriving on the same tick")
	player.position = Vector3(-4, 0.05, 0)
	await physics_frame
	snail._physics_process(1)
	check(snail.visible and snail.collision_layer == 2, "snail respawns once its space clears")
	world.queue_free()
	await process_frame
	print("Actor collision and occupied placement: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func walk(count: int) -> void:
	for i in count:
		await physics_frame
		player._physics_process(1.0 / 60.0)
