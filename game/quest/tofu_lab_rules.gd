class_name TofuLabRules
extends RefCounted
## Host-side lab clues, terminal gate, and one-batch chemical choice.

const TERMINAL_ID: String = "lab_terminal"
const NOTE_ID: String = "shift_note"
const TANK_ID: String = "coagulation_tank"
const PASSWORD_COOLDOWN_MS: int = 500

var run_id: int = 1
var attempt_id: int = 1
var revision: int = 0
var shelf_order: Array[String] = []
var last_sequence: Dictionary = {}
var opening_cleared: bool = false
var note_found: bool = false
var formula_unlocked: bool = false
var carried_bottle: String = ""
var carrier_id: int = 0
var combat_locked: bool = false
var curd_encounter: bool = false
var complete: bool = false
var next_password_ms: int = 0

func configure(run: int, attempt: int, shelf_seed: int) -> void:
	run_id = run
	attempt_id = attempt
	shelf_order = TofuPuzzleContract.CHEMICAL_IDS.duplicate()
	var random := RandomNumberGenerator.new()
	random.seed = shelf_seed
	for index in range(shelf_order.size() - 1, 0, -1):
		var swap: int = random.randi_range(0, index)
		var previous: String = shelf_order[index]
		shelf_order[index] = shelf_order[swap]
		shelf_order[swap] = previous

func content_at(container_id: String) -> String:
	if not container_id.begins_with("container_"): return ""
	var suffix: String = container_id.trim_prefix("container_")
	if suffix.length() != 2 or not suffix.is_valid_int(): return ""
	var index: int = int(suffix)
	return shelf_order[index] if index >= 0 and index < shelf_order.size() else ""

func apply(command: TofuPuzzleCommand, actor_id: int, authorized: bool, mistakes: int, now_ms: int) -> Dictionary:
	if not _valid(command, actor_id, authorized): return _result(false)
	match command.action:
		TofuPuzzleCommand.Action.INSPECT:
			if command.target_id == NOTE_ID:
				note_found = true
				return _changed(command, actor_id, false)
			if content_at(command.target_id) != "" or command.target_id in [TERMINAL_ID, TANK_ID]:
				return _result(true)
		TofuPuzzleCommand.Action.OPEN_TERMINAL:
			return _result(opening_cleared and not combat_locked and command.target_id == TERMINAL_ID)
		TofuPuzzleCommand.Action.SUBMIT_PASSWORD:
			if not opening_cleared or combat_locked or command.target_id != TERMINAL_ID: return _result(false)
			if now_ms < next_password_ms or command.text.is_empty(): return _result(false)
			next_password_ms = now_ms + PASSWORD_COOLDOWN_MS
			if not TofuPuzzleContract.password_matches(command.text): return _changed(command, actor_id, false)
			formula_unlocked = true
			return _changed(command, actor_id, false)
		TofuPuzzleCommand.Action.PICK_UP:
			if not opening_cleared or combat_locked or content_at(command.target_id) == "": return _result(false)
			if carrier_id != 0: return _result(false)
			carried_bottle = command.target_id
			carrier_id = actor_id
			return _changed(command, actor_id, false)
		TofuPuzzleCommand.Action.RETURN_PROP:
			if carrier_id != actor_id or command.target_id != carried_bottle: return _result(false)
			carried_bottle = ""
			carrier_id = 0
			return _changed(command, actor_id, false)
		TofuPuzzleCommand.Action.POUR:
			if not opening_cleared or combat_locked or complete: return _result(false)
			if mistakes >= TofuPuzzleContract.MAX_MISTAKES: return _result(false)
			if command.target_id != TANK_ID or command.object_id != carried_bottle or carrier_id != actor_id: return _result(false)
			var content: String = content_at(carried_bottle)
			carried_bottle = ""
			carrier_id = 0
			complete = content == "nigari"
			combat_locked = not complete
			curd_encounter = false
			return _changed(command, actor_id, not complete)
	return _result(false)

func clear_opening() -> void:
	opening_cleared = true

func clear_encounter() -> void:
	if not combat_locked: return
	if curd_encounter: complete = true
	combat_locked = false
	curd_encounter = false

func release_actor(actor_id: int) -> void:
	if carrier_id != actor_id: return
	carried_bottle = ""
	carrier_id = 0

func capture() -> Dictionary:
	return {"run_id": run_id, "attempt_id": attempt_id, "revision": revision,
		"shelf_order": shelf_order.duplicate(), "last_sequence": last_sequence.duplicate(),
		"opening_cleared": opening_cleared, "note_found": note_found,
		"formula_unlocked": formula_unlocked, "carried_bottle": carried_bottle,
		"carrier_id": carrier_id, "combat_locked": combat_locked,
		"curd_encounter": curd_encounter, "complete": complete}

func restore(data: Dictionary) -> bool:
	if not _valid_snapshot(data): return false
	run_id = int(data.run_id)
	attempt_id = int(data.attempt_id)
	revision = int(data.revision)
	shelf_order.assign(data.shelf_order)
	last_sequence = data.last_sequence.duplicate()
	opening_cleared = data.opening_cleared
	note_found = data.note_found
	formula_unlocked = data.formula_unlocked
	carried_bottle = data.carried_bottle
	carrier_id = data.carrier_id
	combat_locked = data.combat_locked
	curd_encounter = data.curd_encounter
	complete = data.complete
	next_password_ms = 0
	return true

func _valid(command: TofuPuzzleCommand, actor_id: int, authorized: bool) -> bool:
	return authorized and actor_id > 0 and command != null and command.valid_shape() \
		and command.run_id == run_id and command.attempt_id == attempt_id \
		and command.expected_revision == revision \
		and command.sequence > int(last_sequence.get(str(actor_id), 0))

func _changed(command: TofuPuzzleCommand, actor_id: int, mistake: bool) -> Dictionary:
	last_sequence[str(actor_id)] = command.sequence
	revision += 1
	return {"accepted": true, "mistake": mistake, "complete": complete,
		"revision": revision, "curd_encounter": curd_encounter}

func _result(accepted: bool) -> Dictionary:
	return {"accepted": accepted, "mistake": false, "complete": complete, "revision": revision}

func _valid_snapshot(data: Dictionary) -> bool:
	for field: String in ["run_id", "attempt_id", "revision", "carrier_id"]:
		if not TofuPuzzleContract.bounded_integer(data.get(field), 0, 2147483647): return false
	if data.run_id < 1 or data.attempt_id < 1 or data.revision < 0 or data.carrier_id < 0: return false
	for field: String in ["opening_cleared", "note_found", "formula_unlocked", "combat_locked", "curd_encounter", "complete"]:
		if typeof(data.get(field)) != TYPE_BOOL: return false
	if typeof(data.get("shelf_order")) != TYPE_ARRAY or data.shelf_order.size() != 20: return false
	var unique: Dictionary = {}
	for content: Variant in data.shelf_order:
		if not TofuPuzzleContract.CHEMICAL_IDS.has(content) or unique.has(content): return false
		unique[content] = true
	if typeof(data.get("carried_bottle")) != TYPE_STRING: return false
	if data.carried_bottle != "" and not _snapshot_container_valid(data.carried_bottle): return false
	if (data.carrier_id == 0) != (data.carried_bottle == ""): return false
	if data.complete and not data.opening_cleared: return false
	if data.curd_encounter and not data.combat_locked: return false
	if typeof(data.get("last_sequence")) != TYPE_DICTIONARY: return false
	for actor_id: Variant in data.last_sequence.keys():
		if not actor_id is String or not actor_id.is_valid_int() or int(actor_id) < 1: return false
		if not TofuPuzzleContract.bounded_integer(data.last_sequence[actor_id], 1, 2147483647): return false
	return true

func _snapshot_container_valid(container_id: String) -> bool:
	if not container_id.begins_with("container_"): return false
	var suffix: String = container_id.trim_prefix("container_")
	return suffix.length() == 2 and suffix.is_valid_int() and int(suffix) < 20
