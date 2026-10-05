class_name TofuDungeonAttempt
extends RefCounted
## One authoritative production attempt; commands are prechecked for actor access.

var run_id: int = 1
var attempt_id: int = 1
var stage: TofuPuzzleContract.Stage = TofuPuzzleContract.Stage.SORT
var phase: TofuPuzzleContract.Phase = TofuPuzzleContract.Phase.READY
var mistakes: int = 0
var encounter_id: String = ""
var batch_id: String = "batch_1_1"
var sorting := TofuSortingRules.new()
var lab := TofuLabRules.new()
var press := TofuPressRules.new()
var cut := TofuCutRules.new()
var pack := TofuPackRules.new()

func configure(run: int, attempt: int, shelf_seed: int) -> void:
	run_id = run
	attempt_id = attempt
	batch_id = "batch_%d_%d" % [run, attempt]
	sorting = TofuSortingRules.new()
	lab = TofuLabRules.new()
	press = TofuPressRules.new()
	cut = TofuCutRules.new()
	pack = TofuPackRules.new()
	sorting.configure(run, attempt)
	lab.configure(run, attempt, shelf_seed)
	stage = TofuPuzzleContract.Stage.SORT
	phase = TofuPuzzleContract.Phase.READY
	mistakes = 0
	encounter_id = ""

func submit(command: TofuPuzzleCommand, actor_id: int, authorized: bool, now_seconds: float) -> Dictionary:
	if not authorized or command == null or not command.valid_shape(): return _result(false)
	if command.run_id != run_id or command.attempt_id != attempt_id: return _result(false)
	if command.action == TofuPuzzleCommand.Action.ABANDON:
		phase = TofuPuzzleContract.Phase.LOCKED
		encounter_id = ""
		return _result(true)
	if command.action == TofuPuzzleCommand.Action.RESTART and (phase == TofuPuzzleContract.Phase.LOCKED or mistakes >= TofuPuzzleContract.MAX_MISTAKES):
		var shelf: Array[String] = lab.shelf_order.duplicate()
		configure(run_id, attempt_id + 1, 0)
		lab.shelf_order = shelf
		return _result(true)
	if phase != TofuPuzzleContract.Phase.READY and phase != TofuPuzzleContract.Phase.OPERATING: return _result(false)
	if command.is_submission() and mistakes >= TofuPuzzleContract.MAX_MISTAKES: return _result(false)
	match stage:
		TofuPuzzleContract.Stage.SORT: return _sorting(command, actor_id)
		TofuPuzzleContract.Stage.LAB: return _lab(command, actor_id, now_seconds)
		TofuPuzzleContract.Stage.PRESS: return _press(command, actor_id, now_seconds)
		TofuPuzzleContract.Stage.CUT: return _cut(command)
		TofuPuzzleContract.Stage.PACK: return _pack(command, actor_id)
	return _result(false)

func encounter_cleared(id: String) -> bool:
	if phase != TofuPuzzleContract.Phase.COMBAT or id != encounter_id: return false
	encounter_id = ""
	if stage == TofuPuzzleContract.Stage.LAB:
		if not lab.opening_cleared: lab.clear_opening()
		elif lab.combat_locked:
			lab.clear_encounter()
			if lab.complete: _advance(TofuPuzzleContract.Stage.PRESS)
	elif stage == TofuPuzzleContract.Stage.SORT: sorting.clear_penalty()
	elif stage == TofuPuzzleContract.Stage.PRESS: press.clear_rejection()
	elif stage == TofuPuzzleContract.Stage.CUT:
		cut.clear_rejection()
		cut.issue_block(batch_id + "_retry_%d" % mistakes, 6.0)
	phase = TofuPuzzleContract.Phase.LOCKED if mistakes >= TofuPuzzleContract.MAX_MISTAKES else TofuPuzzleContract.Phase.READY
	return true

func boss_defeated(id: String) -> bool:
	if stage != TofuPuzzleContract.Stage.BOSS or phase != TofuPuzzleContract.Phase.COMBAT or id != encounter_id: return false
	encounter_id = ""
	stage = TofuPuzzleContract.Stage.COMPLETE
	phase = TofuPuzzleContract.Phase.COMPLETE
	return true

func release_actor(actor_id: int) -> void:
	sorting.release_actor(actor_id)
	lab.release_actor(actor_id)
	press.release_lease(actor_id)
	pack.release_actor(actor_id)
	if phase == TofuPuzzleContract.Phase.OPERATING and press.active_sample < 0:
		phase = TofuPuzzleContract.Phase.READY

func capture(live: bool = false) -> Dictionary:
	return {"version": TofuPuzzleContract.SCHEMA_VERSION, "run_id": run_id, "attempt_id": attempt_id,
		"stage": int(stage), "phase": int(phase), "mistakes": mistakes, "encounter_id": encounter_id,
		"batch_id": batch_id, "sorting": sorting.capture(), "lab": lab.capture(),
		"press": press.capture(live), "cut": cut.capture(), "pack": pack.capture(live)}

func restore(data: Dictionary, live: bool = false) -> bool:
	return TofuAttemptSnapshot.restore(self, data, live)

func _sorting(command: TofuPuzzleCommand, actor_id: int) -> Dictionary:
	var outcome: Dictionary = sorting.apply(command, actor_id, true, mistakes)
	if outcome.mistake: _penalty()
	elif outcome.accepted and sorting.is_complete():
		_advance(TofuPuzzleContract.Stage.LAB)
		phase = TofuPuzzleContract.Phase.COMBAT
		encounter_id = "lab_opening"
	return _result(bool(outcome.accepted))

func _lab(command: TofuPuzzleCommand, actor_id: int, now_seconds: float) -> Dictionary:
	var outcome: Dictionary = lab.apply(command, actor_id, true, mistakes, int(now_seconds * 1000.0))
	if outcome.mistake: _penalty()
	elif outcome.accepted and lab.complete: _advance(TofuPuzzleContract.Stage.PRESS)
	elif bool(outcome.get("curd_encounter", false)):
		phase = TofuPuzzleContract.Phase.COMBAT
		encounter_id = "lab_curd"
	return _result(bool(outcome.accepted))

func _press(command: TofuPuzzleCommand, actor_id: int, now_seconds: float) -> Dictionary:
	var outcome: TofuPressRules.Outcome = TofuPressRules.Outcome.INVALID
	match command.action:
		TofuPuzzleCommand.Action.SET_PRESS_PRESET:
			if command.object_id in ["accessible", "standard"]: outcome = press.set_accessible(command.object_id == "accessible", actor_id, command.expected_revision)
		TofuPuzzleCommand.Action.START_PRESS:
			if command.target_id == "modern_press": outcome = press.start_modern(actor_id, now_seconds, command.expected_revision)
			elif command.object_id == "soft": outcome = press.begin_traditional(TofuPressRules.Sample.SOFT, actor_id, now_seconds, command.expected_revision)
			elif command.object_id == "firm": outcome = press.begin_traditional(TofuPressRules.Sample.FIRM, actor_id, now_seconds, command.expected_revision)
		TofuPuzzleCommand.Action.PLACE_STONE:
			outcome = press.place_stone(command.object_id, actor_id, now_seconds, command.expected_revision)
		TofuPuzzleCommand.Action.RELEASE_PRESS:
			outcome = press.release_traditional(actor_id, now_seconds, command.expected_revision)
		TofuPuzzleCommand.Action.RETURN_PROP:
			outcome = press.abandon_active(actor_id, command.expected_revision)
		TofuPuzzleCommand.Action.STOP_PRESS:
			outcome = press.stop_modern(actor_id, now_seconds, command.expected_revision)
	if outcome == TofuPressRules.Outcome.REJECTED: _penalty()
	elif outcome == TofuPressRules.Outcome.CERTIFIED and press.certificates.all(func(value: bool) -> bool: return value):
		_advance(TofuPuzzleContract.Stage.CUT)
		cut.issue_block(batch_id + "_block", 6.0)
	if stage == TofuPuzzleContract.Stage.PRESS and phase != TofuPuzzleContract.Phase.COMBAT:
		phase = TofuPuzzleContract.Phase.OPERATING if press.active_sample >= 0 else TofuPuzzleContract.Phase.READY
	return _result(outcome != TofuPressRules.Outcome.INVALID)

func abandon_press(actor_id: int) -> void:
	if press.abandon_active(actor_id, press.revision) == TofuPressRules.Outcome.REJECTED: _penalty()

func poll(now: float) -> void:
	if stage == TofuPuzzleContract.Stage.PRESS and phase == TofuPuzzleContract.Phase.OPERATING:
		if press.poll_modern(now) == TofuPressRules.Outcome.REJECTED: _penalty()

func _cut(command: TofuPuzzleCommand) -> Dictionary:
	if command.action != TofuPuzzleCommand.Action.COMMIT_CUTS: return _result(false)
	var outcome: TofuCutRules.Outcome = cut.commit(command.object_id, command.cuts, command.expected_revision)
	if outcome == TofuCutRules.Outcome.REJECTED: _penalty()
	elif outcome == TofuCutRules.Outcome.COMPLETE:
		_advance(TofuPuzzleContract.Stage.PACK)
		pack.begin_batch(batch_id)
	return _result(outcome != TofuCutRules.Outcome.INVALID)

func _pack(command: TofuPuzzleCommand, actor_id: int) -> Dictionary:
	var outcome: TofuPackRules.Outcome = TofuPackRules.Outcome.INVALID
	var slab: int = int(command.object_id) if command.object_id.is_valid_int() else -1
	var slot: int = int(command.target_id) if command.target_id.is_valid_int() else -1
	match command.action:
		TofuPuzzleCommand.Action.PICK_UP: outcome = pack.reserve(slab, actor_id, command.expected_revision)
		TofuPuzzleCommand.Action.PLACE_SLAB: outcome = pack.place(slab, slot, actor_id, command.expected_revision)
		TofuPuzzleCommand.Action.SEAL_SLOT: outcome = pack.seal(slot, command.expected_revision)
	if outcome == TofuPackRules.Outcome.BOSS_READY:
		_advance(TofuPuzzleContract.Stage.BOSS)
		phase = TofuPuzzleContract.Phase.COMBAT
		encounter_id = "dofufu_boss"
	return _result(outcome != TofuPackRules.Outcome.INVALID)

func _penalty() -> void:
	mistakes += 1
	phase = TofuPuzzleContract.Phase.COMBAT
	encounter_id = "penalty_%02d" % mistakes

func _advance(next_stage: TofuPuzzleContract.Stage) -> void:
	stage = next_stage
	phase = TofuPuzzleContract.Phase.READY

func _result(accepted: bool) -> Dictionary:
	return {"accepted": accepted, "stage": int(stage), "phase": int(phase), "mistakes": mistakes,
		"encounter_id": encounter_id, "difficulty": TofuPuzzleContract.penalty_multiplier(mistakes) if encounter_id.begins_with("penalty_") else 1.0}
