extends SceneTree
## Walk the authored switchback and ramp using the real player capsule and motor.
class RouteInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		return command

var failures: int = 0
var actor: Player
var source := RouteInput.new()

func _initialize() -> void: call_deferred("run")

func walk_to(at: Vector3) -> void:
	for tick in 500:
		var offset := Vector2(at.x - actor.position.x, at.z - actor.position.z)
		if offset.length() < 0.3: break
		source.move = offset.normalized()
		await physics_frame
	source.move = Vector2.ZERO
	if actor.position.distance_to(at) > 0.8:
		failures += 1
		push_error("Route blocked at %s, target %s" % [actor.position, at])

func run() -> void:
	var factory := TofuFactory.new()
	root.add_child(factory)
	factory.ensure_interior()
	factory.reset_gates(6)
	actor = load("res://game/player/player.tscn").instantiate()
	actor.add_child(source)
	actor.command_source = source
	actor.position = Vector3(300,0.1,-176)
	root.add_child(actor)
	await physics_frame
	for at in [Vector3(308,0,-180),Vector3(314,0,-180),Vector3(322,0,-176),Vector3(331,0,-180),Vector3(335,0,-180),Vector3(335,0,-176),Vector3(350,0,-176),Vector3(356,0,-176),Vector3(356,4,-208),Vector3(350,4,-210),Vector3(335,4,-210),Vector3(335,4,-206),Vector3(330,4,-206),Vector3(322,4,-210),Vector3(313,4,-210),Vector3(313,4,-206),Vector3(308,4,-206),Vector3(308,4,-212),Vector3(300,4,-212)]:
		await walk_to(at)
	print("Factory physical route: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
