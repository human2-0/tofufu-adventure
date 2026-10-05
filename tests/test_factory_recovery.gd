extends SceneTree
## Authoritative membership and capsule recovery at repeatable illegal coordinates.

var failures: int = 0
var game: AdventureGame
var dungeon: TofuDungeon

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func command(action: TofuPuzzleCommand.Action, target: String, sequence: int) -> TofuPuzzleCommand:
	var intent := TofuPuzzleCommand.new()
	intent.action = action
	intent.target_id = target
	intent.sequence = sequence
	intent.run_id = dungeon.puzzle.run_id
	intent.attempt_id = dungeon.puzzle.attempt_id
	intent.expected_revision = dungeon.puzzle.sorting.revision
	return intent

func run() -> void:
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await ticks(3)
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.shooting_view.local_input.enabled = false
	dungeon = game.factory_dungeon
	dungeon.set_physics_process(false)
	dungeon.factory.ensure_interior()
	dungeon.state.enter()
	DungeonMembership.enter(dungeon, game.player)
	dungeon._inside = true
	game.inventory.set_slot(6, ItemStack.new(InventoryItem.create_edamame(), 37))
	var inventory: Array = game.inventory.capture()
	var equipment: Dictionary = game.character_equipment.capture()
	var hp: float = game.health.current
	var sequence: int = 0
	for cutaway in [true, false]:
		dungeon.factory.set_cutaway(cutaway)
		for illegal: Vector3 in [Vector3(322, 0.2, -180), Vector3(344, 0.2, -180), Vector3(300, 4.2, -206), Vector3(356, 2, -193), Vector3(324, -3, -193), Vector3(300, 11, -180), Vector3(286, 0.2, -180), Vector3(362, 4.2, -206), Vector3(300, 0.2, -168), Vector3(300, 4.2, -218)]:
			var dock: Vector3 = TofuFactory.object_position("sack_edamame") + Vector3(0, 0.05, 1.5)
			game.player.relocate(dock)
			dungeon._recovery.seed("solo", dock, 0)
			await ticks(1)
			sequence += 1
			check(dungeon.submit_puzzle(command(TofuPuzzleCommand.Action.PICK_UP, "sack_edamame", sequence), game.player).accepted, "carry fixture reserves quest sack")
			game.player.global_position = illegal
			game.player.velocity = Vector3(70, 30, 70)
			game.player.motor.is_dashing = true
			game.player.motor.is_super_dashing = true
			dungeon._recovery.step(dungeon)
			check(game.player.global_position.distance_to(dock) < 0.8, "illegal location restored to capsule-safe anchor: %s cutaway=%s" % [illegal, cutaway])
			check(game.player.velocity.is_zero_approx() and not game.player.motor.is_dashing and not game.player.motor.is_super_dashing, "recovery clears movement impulse")
			check(dungeon.puzzle.sorting.carried_by.is_empty(), "recovery returns carried quest object")
			check(dungeon.actor_in_run(game.player) and dungeon.state.stage == 0 and dungeon.puzzle.mistakes == 0, "recovery preserves membership and cannot skip progression")
			check(game.inventory.capture() == inventory and game.character_equipment.capture() == equipment and game.health.current == hp, "recovery causes no inventory, equipment or health loss")
	# Repeat from a cleared upper-deck checkpoint and forbid a reverse shortcut.
	dungeon.state.stage = 4
	dungeon.puzzle.stage = TofuPuzzleContract.Stage.PACK
	dungeon.factory.reset_gates(4)
	var upper: Vector3 = TofuFactory.recovery_anchor(4)
	game.player.relocate(upper)
	dungeon._recovery.seed("solo", game.player.global_position, 4)
	for illegal: Vector3 in [Vector3(300, 4.2, -206), Vector3(300, 0.2, -180), Vector3(324, -2, -193), Vector3(324, 12, -206)]:
		game.player.global_position = illegal
		dungeon._recovery.step(dungeon)
		check(TofuFactory.room_at(game.player.global_position) == 4, "upper checkpoint corrects illegal transition: %s" % illegal)
		check(dungeon.actor_in_run(game.player), "upper recovery retains run membership")
	print("Factory authoritative recovery: ", "PASS" if failures == 0 else "FAIL")
	for child: Node in root.get_children(): child.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
