class_name TofuSortingRules
extends RefCounted
## Host-side sack ownership and deliberate intake commits.

var run_id: int = 1
var attempt_id: int = 1
var revision: int = 0
var assignments: Dictionary = {}
var carried_by: Dictionary = {}
var last_sequence: Dictionary = {}
var combat_locked: bool = false

func configure(run: int, attempt: int) -> void:
	run_id = run
	attempt_id = attempt

func apply(command: TofuPuzzleCommand, actor_id: int, authorized: bool, mistakes: int) -> Dictionary:
	if not _valid(command, actor_id, authorized): return _result(false)
	match command.action:
		TofuPuzzleCommand.Action.INSPECT:
			if TofuPuzzleContract.SACK_IDS.has(command.target_id) or TofuPuzzleContract.INTAKE_IDS.has(command.target_id):
				return {"accepted": true, "mistake": false, "complete": is_complete(), "revision": revision}
		TofuPuzzleCommand.Action.PICK_UP:
			if combat_locked or not TofuPuzzleContract.SACK_IDS.has(command.target_id): return _result(false)
			if assignments.has(command.target_id) or carried_by.has(command.target_id): return _result(false)
			if carried_by.values().has(actor_id): return _result(false)
			carried_by[command.target_id] = actor_id
			return _changed(command, actor_id, false)
		TofuPuzzleCommand.Action.RETURN_PROP:
			if combat_locked or carried_by.get(command.target_id, -1) != actor_id: return _result(false)
			carried_by.erase(command.target_id)
			return _changed(command, actor_id, false)
		TofuPuzzleCommand.Action.LOAD_INTAKE:
			if combat_locked or mistakes >= TofuPuzzleContract.MAX_MISTAKES: return _result(false)
			if not TofuPuzzleContract.INTAKE_IDS.has(command.target_id): return _result(false)
			if carried_by.get(command.object_id, -1) != actor_id: return _result(false)
			if assignments.values().has(command.target_id): return _result(false)
			carried_by.erase(command.object_id)
			if TofuPuzzleContract.expected_intake(command.object_id) != command.target_id:
				combat_locked = true
				return _changed(command, actor_id, true)
			assignments[command.object_id] = command.target_id
			return _changed(command, actor_id, false)
	return _result(false)

func release_actor(actor_id: int) -> void:
	for sack_id: String in carried_by.keys():
		if carried_by[sack_id] == actor_id: carried_by.erase(sack_id)

func clear_penalty() -> void:
	combat_locked = false

func is_complete() -> bool:
	return assignments.size() == TofuPuzzleContract.SACK_IDS.size()

func capture() -> Dictionary:
	return {"run_id": run_id, "attempt_id": attempt_id, "revision": revision,
		"assignments": assignments.duplicate(), "carried_by": carried_by.duplicate(),
		"last_sequence": last_sequence.duplicate(), "combat_locked": combat_locked}

func restore(data: Dictionary) -> bool:
	for field: String in ["assignments", "carried_by", "last_sequence"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY: return false
	var saved_assignments: Dictionary = data.get("assignments", {})
	var saved_carried: Dictionary = data.get("carried_by", {})
	var saved_sequences: Dictionary = data.get("last_sequence", {})
	if not _valid_snapshot(data, saved_assignments, saved_carried, saved_sequences): return false
	run_id = int(data.run_id)
	attempt_id = int(data.attempt_id)
	revision = int(data.revision)
	assignments = saved_assignments.duplicate()
	carried_by = saved_carried.duplicate()
	last_sequence = saved_sequences.duplicate()
	combat_locked = data.combat_locked
	return true

func _valid(command: TofuPuzzleCommand, actor_id: int, authorized: bool) -> bool:
	return authorized and actor_id > 0 and command != null and command.valid_shape() \
		and command.run_id == run_id and command.attempt_id == attempt_id \
		and command.expected_revision == revision \
		and command.sequence > int(last_sequence.get(str(actor_id), 0))

func _changed(command: TofuPuzzleCommand, actor_id: int, mistake: bool) -> Dictionary:
	last_sequence[str(actor_id)] = command.sequence
	revision += 1
	return {"accepted": true, "mistake": mistake, "complete": is_complete(), "revision": revision}

func _result(accepted: bool) -> Dictionary:
	return {"accepted": accepted, "mistake": false, "complete": is_complete(), "revision": revision}

func _valid_snapshot(data: Dictionary, saved_assignments: Dictionary, saved_carried: Dictionary, saved_sequences: Dictionary) -> bool:
	if not TofuPuzzleContract.bounded_integer(data.get("run_id"), 1, 2147483647): return false
	if not TofuPuzzleContract.bounded_integer(data.get("attempt_id"), 1, 2147483647): return false
	if not TofuPuzzleContract.bounded_integer(data.get("revision"), 0, 2147483647): return false
	if typeof(data.get("combat_locked")) != TYPE_BOOL: return false
	if saved_assignments.size() > 3 or saved_carried.size() > 3: return false
	for sack_id: String in saved_assignments.keys():
		if TofuPuzzleContract.expected_intake(sack_id) != saved_assignments[sack_id]: return false
	for sack_id: String in saved_carried.keys():
		if not TofuPuzzleContract.SACK_IDS.has(sack_id) or saved_assignments.has(sack_id): return false
		if not TofuPuzzleContract.bounded_integer(saved_carried[sack_id], 1, 2147483647): return false
	if saved_carried.values().size() != _unique_count(saved_carried.values()): return false
	for actor_id: Variant in saved_sequences.keys():
		if not actor_id is String or not actor_id.is_valid_int() or int(actor_id) < 1: return false
		if not TofuPuzzleContract.bounded_integer(saved_sequences[actor_id], 1, 2147483647): return false
	return true

func _unique_count(values: Array) -> int:
	var unique: Dictionary = {}
	for value: Variant in values: unique[value] = true
	return unique.size()
