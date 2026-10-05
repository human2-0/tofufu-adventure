extends SceneTree
## The live dungeon uses the new authority rules and real factory scene anchors.

var failures: int = 0
var sequence: int = 0

func _initialize() -> void: call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		push_error(label)

func command(dungeon: TofuDungeon, action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> TofuPuzzleCommand:
	sequence += 1
	var intent := TofuPuzzleCommand.new()
	intent.action = action
	intent.target_id = target
	intent.object_id = object_id
	intent.run_id = dungeon.puzzle.run_id
	intent.attempt_id = dungeon.puzzle.attempt_id
	intent.sequence = sequence
	match dungeon.puzzle.stage:
		TofuPuzzleContract.Stage.SORT: intent.expected_revision = dungeon.puzzle.sorting.revision
		TofuPuzzleContract.Stage.LAB: intent.expected_revision = dungeon.puzzle.lab.revision
		TofuPuzzleContract.Stage.PRESS: intent.expected_revision = dungeon.puzzle.press.revision
		TofuPuzzleContract.Stage.CUT: intent.expected_revision = dungeon.puzzle.cut.revision
		TofuPuzzleContract.Stage.PACK: intent.expected_revision = dungeon.puzzle.pack.revision
	return intent

func near(game: Node3D, id: String) -> void:
	game.player.relocate(TofuFactory.object_position(id) + Vector3(0, 0.05, 1.5))

func run() -> void:
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	var dungeon: TofuDungeon = game.factory_dungeon
	check(dungeon.puzzle_enabled, "new adventure uses revised dungeon")
	dungeon._enter()
	check(dungeon.actor_in_run(game.player), "entry records run membership")
	check(dungeon.journal.visible, "entrance opens dismissible briefing")
	dungeon.journal.close()
	DungeonRunActions.toggle_journal(dungeon)
	check(dungeon.journal.visible, "briefing reopens in recipe journal")
	dungeon.journal.close()
	for index in 3:
		var sack: String = TofuPuzzleContract.SACK_IDS[index]
		var intake: String = TofuPuzzleContract.INTAKE_IDS[index]
		near(game, sack)
		var picked: Dictionary = dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PICK_UP, sack), game.player)
		check(picked.accepted, "sack picked up")
		near(game, intake)
		var loaded: Dictionary = dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.LOAD_INTAKE, intake, sack), game.player)
		check(loaded.accepted, "correct intake committed")
	check(dungeon.puzzle.stage == TofuPuzzleContract.Stage.LAB and dungeon.puzzle.encounter_id == "lab_opening", "mill leads to lab opening")
	dungeon._recovery.seed("solo", TofuFactory.recovery_anchor(1), 1)
	game.player.relocate(TofuFactory.recovery_anchor(1))
	dungeon._physics_process(0.016)
	check(dungeon._enemies.size() == 3, "mandatory lab encounter spawns")
	for enemy: FactoryBean in dungeon._enemies.duplicate(): enemy.target.damage(999)
	check(dungeon.puzzle.phase == TofuPuzzleContract.Phase.READY and dungeon.puzzle.lab.opening_cleared, "lab encounter clears once")
	near(game, "shift_note")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.INSPECT, "shift_note"), game.player).accepted, "reachable note records clue")
	near(game, "lab_terminal")
	var password := command(dungeon, TofuPuzzleCommand.Action.SUBMIT_PASSWORD, "lab_terminal")
	password.text = "unknown"
	check(dungeon.submit_puzzle(password, game.player).accepted and not dungeon.puzzle.lab.formula_unlocked, "unsolved password leaves formula hidden without blocking ingredient trials")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(dungeon.capture()))
	check(saved.has("puzzle") and saved.has("reward_ledger"), "checkpoint carries puzzle and ledger")
	check(FactorySaveValidation.puzzle(saved.puzzle), "saved puzzle fits bounded local schema")
	var nigari_container: String = ""
	for index in 20:
		var candidate: String = "container_%02d" % index
		if dungeon.puzzle.lab.content_at(candidate) == "nigari": nigari_container = candidate
	check(not nigari_container.is_empty(), "one host-owned Nigari container exists")
	near(game, nigari_container)
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PICK_UP, nigari_container), game.player).accepted, "Nigari bottle picked")
	near(game, "coagulation_tank")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.POUR, "coagulation_tank", nigari_container), game.player).accepted, "pour without terminal recipe accepted")
	check(dungeon.puzzle.encounter_id.is_empty() and dungeon.puzzle.stage == TofuPuzzleContract.Stage.PRESS, "correct coagulant releases press without monsters")
	near(game, "traditional_press")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.START_PRESS, "traditional_press", "soft"), game.player).accepted, "soft trial starts")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PLACE_STONE, "traditional_press", "stone_1"), game.player).accepted, "first stone placed")
	await create_timer(3.0).timeout
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.RELEASE_PRESS, "traditional_press"), game.player).accepted, "soft sample certified")
	check(dungeon.puzzle.press.certificates[0], "soft certificate persists")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.START_PRESS, "traditional_press", "firm"), game.player).accepted, "firm trial starts")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PLACE_STONE, "traditional_press", "stone_1"), game.player).accepted, "firm first stone")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PLACE_STONE, "traditional_press", "stone_2"), game.player).accepted, "firm second stone")
	await create_timer(5.0).timeout
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.RELEASE_PRESS, "traditional_press"), game.player).accepted, "firm sample certified")
	near(game, "modern_press")
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.START_PRESS, "modern_press"), game.player).accepted, "modern pressure starts")
	await create_timer(6.88).timeout
	check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.STOP_PRESS, "modern_press"), game.player).accepted, "extra firm sample certified")
	check(dungeon.puzzle.stage == TofuPuzzleContract.Stage.CUT, "three certificates unlock cutter")
	near(game, "cutter")
	var cuts := command(dungeon, TofuPuzzleCommand.Action.COMMIT_CUTS, "cutter", dungeon.puzzle.cut.block_id)
	cuts.cuts = [1.0, 2.0, 3.0, 4.0, 5.0]
	check(dungeon.submit_puzzle(cuts, game.player).accepted, "six equal widths cut")
	check(dungeon.puzzle.stage == TofuPuzzleContract.Stage.PACK, "cut produces six slabs")
	for index in 6:
		near(game, "slab_%d" % index)
		check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PICK_UP, "", str(index)), game.player).accepted, "slab reserved %d" % index)
		near(game, "package_%d" % index)
		check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.PLACE_SLAB, str(index), str(index)), game.player).accepted, "slab placed %d" % index)
		check(dungeon.submit_puzzle(command(dungeon, TofuPuzzleCommand.Action.SEAL_SLOT, str(index)), game.player).accepted, "package sealed %d" % index)
	check(dungeon.puzzle.encounter_id == "dofufu_boss", "sixth seal triggers boss once")
	check(TofuFactory.room_at(game.player.global_position) == 5 and (dungeon.factory.gates[4].get_child(0) as StaticBody3D).collision_layer == 1, "participants enter before arena gate seals")
	dungeon._physics_process(0.016)
	check(dungeon._enemies.size() == 1 and dungeon._enemies[0] is Dofufu, "Dofufu spawns in arena")
	for enemy: FactoryBean in dungeon._enemies.duplicate(): enemy.target.damage(9999)
	check(dungeon.puzzle.stage == TofuPuzzleContract.Stage.COMPLETE and dungeon.state.completed, "boss defeat completes factory")
	check(dungeon.rewards.refinery_unlocked("solo"), "participating character receives refinery entitlement")
	check(dungeon.journal.visible, "unlock tutorial opens after confirmed boss defeat")
	dungeon.journal.close()
	var boss_drops: int = 0
	for drop: WorldItemDrop in game.world_items.pool.drops.values():
		if drop.item_id == "mature_bean" and drop.count == 10: boss_drops += 1
	check(boss_drops == 1, "boss pays one shared ten-bean stack")
	check(WorldProtocol.factory(JSON.parse_string(JSON.stringify(dungeon.capture_world()))), "completed factory snapshot passes network validation")
	print("Tofu active route: ", "PASS" if failures == 0 else "FAIL")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
