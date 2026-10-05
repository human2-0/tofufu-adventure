extends SceneTree
## Exercise the app authority boundary with the actual factory scene and actor.

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if ok: return
	failures += 1
	push_error("FAIL: " + label)

func run() -> void:
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	var dungeon: TofuDungeon = game.factory_dungeon
	dungeon._enter()
	dungeon.set_physics_process(false)
	var attempt := TofuDungeonAttempt.new()
	attempt.configure(7, 2, 19)
	var runtime := DungeonPuzzleRuntime.new()
	runtime.configure(dungeon, attempt)
	var actor: Player = game.player
	var inspect := command(attempt, TofuPuzzleCommand.Action.INSPECT, "sack_edamame", "", 1, 0)
	actor.relocate(Vector3(294, 0.2, -172.8))
	await physics_frame
	check(runtime.submit(inspect, actor, 1.0).accepted, "nearby in-run actor can inspect a sack")
	check(attempt.mistakes == 0, "inspection has no penalty")
	actor.relocate(Vector3(322, 0.2, -180))
	check(not runtime.submit(inspect, actor, 1.1).accepted, "wrong room cannot inspect a sack")
	actor.relocate(Vector3(294, 0.2, -172.8))
	var forged := command(attempt, TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_oil", "sack_edamame", 2, 0)
	check(not runtime.submit(forged, actor, 1.2).accepted, "remote intake commit is rejected")
	check(attempt.mistakes == 0, "invalid commit creates no penalty")
	var pickup := command(attempt, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame", "", 3, 0)
	check(runtime.submit(pickup, actor, 1.3).accepted, "nearby actor reserves sack")
	actor.relocate(Vector3(294, 0.2, -182.4))
	await physics_frame
	var wrong := command(attempt, TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_chilled", "sack_edamame", 4, 1)
	check(runtime.submit(wrong, actor, 1.4).accepted, "matching intake accepts committed sack")
	check(attempt.sorting.assignments.size() == 1 and attempt.mistakes == 0, "matching intake records one assignment")
	check(not runtime.submit(wrong, actor, 1.5).accepted, "replayed commit is rejected")
	check(attempt.sorting.assignments.size() == 1, "replay cannot duplicate assignment")
	check(not runtime.encounter_cleared("unknown"), "unissued encounter cannot clear gates")
	attempt.mistakes = 10
	attempt.phase = TofuPuzzleContract.Phase.LOCKED
	var restart := command(attempt, TofuPuzzleCommand.Action.RESTART, "", "", 5, 0)
	check(runtime.submit(restart, actor, 2.0).accepted and attempt.attempt_id == 3 and attempt.mistakes == 0, "locked attempt restarts at authority")
	var abandon := command(attempt, TofuPuzzleCommand.Action.ABANDON, "", "", 6, 0)
	check(runtime.submit(abandon, actor, 2.1).accepted and not dungeon.actor_in_run(actor), "explicit evacuation releases run membership")
	print("Dungeon puzzle runtime: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

func command(attempt: TofuDungeonAttempt, action: TofuPuzzleCommand.Action, target: String, object: String, sequence: int, revision: int) -> TofuPuzzleCommand:
	var value := TofuPuzzleCommand.new()
	value.action = action
	value.target_id = target
	value.object_id = object
	value.run_id = attempt.run_id
	value.attempt_id = attempt.attempt_id
	value.sequence = sequence
	value.expected_revision = revision
	return value
