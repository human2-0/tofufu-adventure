extends SceneTree
## Ordinary Player locomotion over every flight, turn and deck joint, in both directions.

class WalkInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_position: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		return command

var failures: int = 0
var castle: LavaCastle
var actor: Player
var input := WalkInput.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	castle = LavaCastle.new()
	root.add_child(castle)
	actor = load("res://game/player/player.tscn").instantiate()
	root.add_child(actor)
	actor.add_child(input)
	actor.command_source = input
	await physics_frame
	for deck in 3:
		var side := -1.0 if deck % 2 == 0 else 1.0
		actor.relocate(castle.to_global(Vector3(0, deck * 8 + 0.05, side * 26)))
		for at in [Vector3(0, deck * 8 + 4, side * 53), Vector3(8, deck * 8 + 4, side * 53), Vector3(8, deck * 8 + 8, side * 30), Vector3(0, deck * 8 + 8, side * 30), Vector3(0, deck * 8 + 8, side * 24)]: await walk(at)
		check(absf(actor.global_position.y - castle.global_position.y - (deck + 1) * 8) < 0.1 and actor.is_on_floor(), "ascent reaches and joins the next floor %d" % deck)
		for at in [Vector3(0, deck * 8 + 8, side * 30), Vector3(8, deck * 8 + 8, side * 30), Vector3(8, deck * 8 + 4, side * 53), Vector3(0, deck * 8 + 4, side * 53), Vector3(0, deck * 8, side * 26)]: await walk(at)
		check(absf(actor.global_position.y - castle.global_position.y - deck * 8) < 0.1 and actor.is_on_floor(), "descent joins its original floor %d" % deck)
	actor.queue_free()
	castle.queue_free()
	await process_frame
	print("Castle stair joints: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func walk(local: Vector3) -> void:
	var at := castle.to_global(local)
	var reached := false
	for tick in 460:
		var direction := Vector2(at.x - actor.global_position.x, at.z - actor.global_position.z)
		if direction.length() < 0.22:
			reached = true
			break
		input.move = direction.normalized()
		await physics_frame
	input.move = Vector2.ZERO
	for tick in 4: await physics_frame
	check(reached, "physical stair corner %s, actor %s" % [at, actor.global_position])

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
