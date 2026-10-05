class_name TofuAttemptSnapshot
extends RefCounted
## Validates a complete puzzle before replacing authority state.

static func restore(attempt: TofuDungeonAttempt, data: Dictionary, live: bool) -> bool:
	if data.get("version") != TofuPuzzleContract.SCHEMA_VERSION: return false
	for field: String in ["run_id", "attempt_id", "stage", "phase", "mistakes"]:
		if not TofuPuzzleContract.bounded_integer(data.get(field), 0, 2147483647): return false
	if data.run_id < 1 or data.attempt_id < 1 or data.stage < 0 or data.stage > TofuPuzzleContract.Stage.COMPLETE: return false
	if data.phase < 0 or data.phase > TofuPuzzleContract.Phase.COMPLETE: return false
	if data.mistakes < 0 or data.mistakes > TofuPuzzleContract.MAX_MISTAKES: return false
	if not data.get("encounter_id") is String or data.encounter_id.length() > 48: return false
	if not data.get("batch_id") is String or data.batch_id != "batch_%d_%d" % [data.run_id, data.attempt_id]: return false
	if (data.phase == TofuPuzzleContract.Phase.COMBAT) != (not data.encounter_id.is_empty()): return false
	for field: String in ["sorting", "lab", "press", "cut", "pack"]:
		if not data.get(field) is Dictionary: return false
	var next_sort := TofuSortingRules.new()
	var next_lab := TofuLabRules.new()
	var next_press := TofuPressRules.new()
	var next_cut := TofuCutRules.new()
	var next_pack := TofuPackRules.new()
	if not next_sort.restore(data.sorting) or not next_lab.restore(data.lab): return false
	if not next_press.restore(data.press, live) or not next_cut.restore(data.cut) or not next_pack.restore(data.pack, live): return false
	if next_sort.run_id != data.run_id or next_lab.run_id != data.run_id: return false
	if next_sort.attempt_id != data.attempt_id or next_lab.attempt_id != data.attempt_id: return false
	if not _progression(data, next_sort, next_lab, next_press, next_cut, next_pack): return false
	attempt.run_id = int(data.run_id)
	attempt.attempt_id = int(data.attempt_id)
	attempt.stage = int(data.stage)
	attempt.phase = int(data.phase)
	if not live and attempt.phase == TofuPuzzleContract.Phase.OPERATING: attempt.phase = TofuPuzzleContract.Phase.READY
	attempt.mistakes = int(data.mistakes)
	attempt.encounter_id = data.encounter_id
	attempt.batch_id = data.batch_id
	attempt.sorting = next_sort
	attempt.lab = next_lab
	attempt.press = next_press
	attempt.cut = next_cut
	if not live:
		next_sort.carried_by.clear()
		next_lab.release_actor(next_lab.carrier_id)
	attempt.pack = next_pack
	return true

static func _progression(data: Dictionary, sorting: TofuSortingRules, lab: TofuLabRules, press: TofuPressRules, cut: TofuCutRules, pack: TofuPackRules) -> bool:
	var stage: int = int(data.stage)
	if stage >= TofuPuzzleContract.Stage.LAB and not sorting.is_complete(): return false
	if stage >= TofuPuzzleContract.Stage.PRESS and not lab.complete: return false
	if stage >= TofuPuzzleContract.Stage.CUT and not press.certificates.all(func(value: bool) -> bool: return value): return false
	if stage >= TofuPuzzleContract.Stage.PACK and (not cut.completed or pack.batch_id != data.batch_id): return false
	if stage >= TofuPuzzleContract.Stage.BOSS and not pack.boss_ready: return false
	if (stage == TofuPuzzleContract.Stage.COMPLETE) != (int(data.phase) == TofuPuzzleContract.Phase.COMPLETE): return false
	var encounter: String = data.encounter_id
	if not encounter.is_empty():
		if not TofuRewardLedger.valid_encounter(encounter): return false
		if encounter.begins_with("penalty_") and encounter != "penalty_%02d" % int(data.mistakes): return false
		if encounter in ["lab_opening", "lab_curd"] and stage != TofuPuzzleContract.Stage.LAB: return false
		if encounter == "dofufu_boss" and stage != TofuPuzzleContract.Stage.BOSS: return false
	return true

static func migrate_completed(attempt: TofuDungeonAttempt) -> void:
	attempt.sorting.configure(attempt.run_id, attempt.attempt_id)
	if attempt.lab.shelf_order.is_empty():
		attempt.lab.configure(attempt.run_id, attempt.attempt_id, 0)
	for sack: String in TofuPuzzleContract.SACK_IDS:
		attempt.sorting.assignments[sack] = TofuPuzzleContract.expected_intake(sack)
	attempt.lab.opening_cleared = true
	attempt.lab.formula_unlocked = true
	attempt.lab.complete = true
	attempt.press.certificates = [true, true, true]
	attempt.cut.issue_block(attempt.batch_id + "_block", 6.0)
	attempt.cut.commit(attempt.cut.block_id, [1.0, 2.0, 3.0, 4.0, 5.0], attempt.cut.revision)
	attempt.pack.begin_batch(attempt.batch_id)
	for index in 6:
		attempt.pack.reserve(index, 1, attempt.pack.revision)
		attempt.pack.place(index, index, 1, attempt.pack.revision)
		attempt.pack.seal(index, attempt.pack.revision)
	attempt.stage = TofuPuzzleContract.Stage.COMPLETE
	attempt.phase = TofuPuzzleContract.Phase.COMPLETE
	attempt.encounter_id = ""
