extends SceneTree
## Authority transition smoke test from sorting through boss entitlement.

var failed: int = 0
var sequence: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failed += 1
		push_error(label)

func command(attempt: TofuDungeonAttempt, action: TofuPuzzleCommand.Action, target: String, object_id: String = "") -> TofuPuzzleCommand:
	sequence += 1
	var result := TofuPuzzleCommand.new()
	result.action = action
	result.target_id = target
	result.object_id = object_id
	result.run_id = attempt.run_id
	result.attempt_id = attempt.attempt_id
	result.sequence = sequence
	match attempt.stage:
		TofuPuzzleContract.Stage.SORT: result.expected_revision = attempt.sorting.revision
		TofuPuzzleContract.Stage.LAB: result.expected_revision = attempt.lab.revision
		TofuPuzzleContract.Stage.PRESS: result.expected_revision = attempt.press.revision
		TofuPuzzleContract.Stage.CUT: result.expected_revision = attempt.cut.revision
		TofuPuzzleContract.Stage.PACK: result.expected_revision = attempt.pack.revision
	return result

func run() -> void:
	var attempt := TofuDungeonAttempt.new()
	attempt.configure(7, 1, 45)
	var wrong := command(attempt, TofuPuzzleCommand.Action.PICK_UP, "sack_edamame")
	check(attempt.submit(wrong, 1, true, 0).accepted, "pick up is reversible")
	var load := command(attempt, TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_oil", "sack_edamame")
	var rejected := attempt.submit(load, 1, true, 0)
	check(rejected.accepted and rejected.mistakes == 1 and rejected.phase == TofuPuzzleContract.Phase.COMBAT, "mistake creates one penalty")
	check(not attempt.submit(load, 1, true, 0).accepted and attempt.mistakes == 1, "replay cannot create a wave")
	check(attempt.encounter_cleared("penalty_01"), "penalty clears")
	for index in 3:
		var sack: String = TofuPuzzleContract.SACK_IDS[index]
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.PICK_UP, sack), 1, true, 0).accepted, "sack pickup")
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.LOAD_INTAKE, TofuPuzzleContract.INTAKE_IDS[index], sack), 1, true, 0).accepted, "correct intake")
	check(attempt.stage == TofuPuzzleContract.Stage.LAB and attempt.encounter_id == "lab_opening", "sorting starts lab encounter")
	check(attempt.encounter_cleared("lab_opening"), "lab handling unlocked")
	var password := command(attempt, TofuPuzzleCommand.Action.SUBMIT_PASSWORD, "lab_terminal")
	password.text = "  tofufu  "
	check(attempt.submit(password, 1, true, 1).accepted and attempt.lab.formula_unlocked, "canonical password variants")
	var nigari_slot: int = attempt.lab.shelf_order.find("nigari")
	var bottle := "container_%02d" % nigari_slot
	check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.PICK_UP, bottle), 1, true, 2).accepted, "bottle pickup")
	check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.POUR, "coagulation_tank", bottle), 1, true, 2).accepted, "nigari pour")
	check(attempt.encounter_id.is_empty() and attempt.stage == TofuPuzzleContract.Stage.PRESS, "correct recipe releases press without monsters")
	for sample in ["soft", "firm"]:
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.START_PRESS, "traditional_press", sample), 1, true, 5).accepted, "traditional press starts")
		var count: int = 1 if sample == "soft" else 2
		for stone in count:
			check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.PLACE_STONE, "traditional_press", "stone_%d" % (stone + 1)), 1, true, 5).accepted, "stone placed")
		var end: float = 8.0 if sample == "soft" else 10.0
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.RELEASE_PRESS, "traditional_press"), 1, true, end).accepted, "sample certified")
	check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.START_PRESS, "modern_press"), 1, true, 12).accepted, "modern press starts")
	check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.STOP_PRESS, "modern_press"), 1, true, 18.8).accepted, "extra firm stop")
	check(attempt.stage == TofuPuzzleContract.Stage.CUT, "presses release cutter")
	var cuts := command(attempt, TofuPuzzleCommand.Action.COMMIT_CUTS, "cutter", attempt.cut.block_id)
	cuts.cuts = [1.0, 2.0, 3.0, 4.0, 5.0]
	check(attempt.submit(cuts, 1, true, 20).accepted and attempt.stage == TofuPuzzleContract.Stage.PACK, "six equal slabs")
	for slab in 6:
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.PICK_UP, "", str(slab)), 1, true, 21).accepted, "slab reserved")
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.PLACE_SLAB, str(slab), str(slab)), 1, true, 21).accepted, "slab placed")
		check(attempt.submit(command(attempt, TofuPuzzleCommand.Action.SEAL_SLOT, str(slab)), 1, true, 21).accepted, "slot sealed")
	check(attempt.stage == TofuPuzzleContract.Stage.BOSS and attempt.encounter_id == "dofufu_boss", "sixth seal starts boss once")
	check(attempt.boss_defeated("dofufu_boss") and not attempt.boss_defeated("dofufu_boss"), "boss completes once")
	var restored := TofuDungeonAttempt.new()
	var encoded: Variant = JSON.parse_string(JSON.stringify(attempt.capture()))
	check(encoded is Dictionary and restored.restore(encoded) and restored.stage == TofuPuzzleContract.Stage.COMPLETE, "complete attempt survives JSON restore")
	var capped := TofuDungeonAttempt.new()
	capped.configure(7, 3, 81)
	capped.mistakes = 10
	capped.phase = TofuPuzzleContract.Phase.COMBAT
	capped.encounter_id = "penalty_10"
	var shelf: Array[String] = capped.lab.shelf_order.duplicate()
	check(capped.encounter_cleared("penalty_10") and capped.phase == TofuPuzzleContract.Phase.LOCKED, "tenth penalty closes submissions")
	check(not capped.submit(command(capped, TofuPuzzleCommand.Action.PICK_UP, "sack_mature"), 1, true, 0).accepted, "locked attempt refuses production")
	check(capped.submit(command(capped, TofuPuzzleCommand.Action.RESTART, ""), 1, true, 0).accepted, "fresh attempt restarts from menu action")
	check(capped.attempt_id == 4 and capped.mistakes == 0 and capped.lab.shelf_order == shelf, "restart resets difficulty and retains shelf positions")
	var legacy := TofuDungeonAttempt.new()
	TofuAttemptSnapshot.migrate_completed(legacy)
	var migrated := TofuDungeonAttempt.new()
	check(migrated.restore(JSON.parse_string(JSON.stringify(legacy.capture()))) and migrated.stage == TofuPuzzleContract.Stage.COMPLETE, "earned legacy completion migrates to a valid future checkpoint")
	print("Tofu attempt: ", "PASS" if failed == 0 else "FAIL")
	quit(1 if failed else 0)
