extends SceneTree

var failures: int = 0
var serial: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	push_error(message)

func command(action: TofuPuzzleCommand.Action, target: String, object: String, revision: int) -> TofuPuzzleCommand:
	serial += 1
	var result := TofuPuzzleCommand.new()
	result.action = action
	result.target_id = target
	result.object_id = object
	result.run_id = 7
	result.attempt_id = 2
	result.sequence = serial
	result.expected_revision = revision
	return result

func run() -> void:
	var sort := TofuSortingRules.new()
	sort.configure(7, 2)
	for sack_id: String in TofuPuzzleContract.SACK_IDS:
		for intake_id: String in TofuPuzzleContract.INTAKE_IDS:
			var trial := TofuSortingRules.new()
			trial.configure(7, 2)
			var pickup := command(TofuPuzzleCommand.Action.PICK_UP, sack_id, "", trial.revision)
			check(trial.apply(pickup, 1, true, 0).accepted, "pickup %s" % sack_id)
			var load_cmd := command(TofuPuzzleCommand.Action.LOAD_INTAKE, intake_id, sack_id, trial.revision)
			var result: Dictionary = trial.apply(load_cmd, 1, true, 0)
			var right: bool = intake_id == TofuPuzzleContract.expected_intake(sack_id)
			check(result.accepted and result.mistake != right, "sorting case %s / %s" % [sack_id, intake_id])
			check(trial.assignments.has(sack_id) == right, "routing state")
			check(not trial.apply(load_cmd, 1, true, 0).accepted, "replay rejected")
			trial.clear_penalty()
			var retry: Dictionary = trial.apply(command(TofuPuzzleCommand.Action.PICK_UP, sack_id, "", trial.revision), 1, true, 0)
			check(retry.accepted != right, "processed sack unavailable")
	for sack_id: String in TofuPuzzleContract.SACK_IDS:
		check(sort.apply(command(TofuPuzzleCommand.Action.PICK_UP, sack_id, "", sort.revision), 1, true, 0).accepted, "pickup to complete")
		check(sort.apply(command(TofuPuzzleCommand.Action.LOAD_INTAKE, TofuPuzzleContract.expected_intake(sack_id), sack_id, sort.revision), 1, true, 0).accepted, "route to complete")
	check(sort.is_complete(), "three assignments complete sorting")
	var stale := command(TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_tofu", "sack_mature", sort.revision - 1)
	check(not sort.apply(stale, 1, true, 0).accepted, "stale revision rejected")
	var untrusted := command(TofuPuzzleCommand.Action.INSPECT, "sack_mature", "", sort.revision)
	check(not sort.apply(untrusted, 1, false, 0).accepted, "unauthorized actor rejected")
	var cap := TofuSortingRules.new()
	cap.configure(7, 2)
	check(cap.apply(command(TofuPuzzleCommand.Action.PICK_UP, "sack_mature", "", cap.revision), 1, true, 10).accepted, "pickup remains reversible at cap")
	check(not cap.apply(command(TofuPuzzleCommand.Action.LOAD_INTAKE, "intake_oil", "sack_mature", cap.revision), 1, true, 10).accepted, "eleventh mistake blocked")
	var sort_restored := TofuSortingRules.new()
	check(sort_restored.restore(sort.capture()) and sort_restored.is_complete(), "sorting persists")
	var bad_sort: Dictionary = sort.capture()
	bad_sort.assignments["sack_mature"] = "intake_oil"
	check(not sort_restored.restore(bad_sort), "malformed sorting rejected")
	bad_sort = sort.capture()
	bad_sort.assignments = []
	check(not sort_restored.restore(bad_sort), "invalid assignment type rejected")

	var lab := TofuLabRules.new()
	lab.configure(7, 2, 218)
	check(lab.shelf_order.size() == 20, "twenty chemicals")
	var unopened := command(TofuPuzzleCommand.Action.SUBMIT_PASSWORD, TofuLabRules.TERMINAL_ID, "", lab.revision)
	unopened.text = "Tofufu"
	check(not lab.apply(unopened, 1, true, 0, 1000).accepted, "opening encounter gates terminal")
	lab.clear_opening()
	check(lab.apply(command(TofuPuzzleCommand.Action.INSPECT, TofuLabRules.NOTE_ID, "", lab.revision), 1, true, 0, 1000).accepted and lab.note_found, "note discovery")
	var password := command(TofuPuzzleCommand.Action.SUBMIT_PASSWORD, TofuLabRules.TERMINAL_ID, "", lab.revision)
	password.text = "  tOfUfU  "
	check(lab.apply(password, 1, true, 0, 1000).accepted and lab.formula_unlocked, "password normalization")
	var early := command(TofuPuzzleCommand.Action.SUBMIT_PASSWORD, TofuLabRules.TERMINAL_ID, "", lab.revision)
	early.text = "wrong"
	check(not lab.apply(early, 1, true, 0, 1200).accepted, "password cooldown")
	check(lab.apply(early, 1, true, 0, 1500).accepted and lab.formula_unlocked, "wrong password no penalty")
	for index in 20:
		var container_id: String = "container_%02d" % index
		var content: String = lab.content_at(container_id)
		var trial := TofuLabRules.new()
		trial.configure(7, 2, 218)
		trial.clear_opening()
		check(trial.apply(command(TofuPuzzleCommand.Action.PICK_UP, container_id, "", trial.revision), 1, true, 0, 2000).accepted, "bottle pickup")
		var pour := command(TofuPuzzleCommand.Action.POUR, TofuLabRules.TANK_ID, container_id, trial.revision)
		var outcome: Dictionary = trial.apply(pour, 1, true, 0, 2000)
		check(outcome.accepted and outcome.mistake == (content != "nigari"), "chemical result %s" % content)
		check(not trial.apply(pour, 1, true, 0, 2000).accepted, "pour replay")
		trial.clear_encounter()
		check(trial.complete == (content == "nigari"), "curd encounter completion")
		var restored_trial := TofuLabRules.new()
		check(restored_trial.restore(trial.capture()) and not restored_trial.formula_unlocked, "trial without login survives save")
	var saved: Dictionary = lab.capture()
	var lab_restored := TofuLabRules.new()
	check(lab_restored.restore(saved) and lab_restored.shelf_order == lab.shelf_order, "shelf positions persist")
	saved.shelf_order[0] = saved.shelf_order[1]
	check(not lab_restored.restore(saved), "duplicate shelf identity rejected")
	print("Tofu sorting/lab rules: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)
