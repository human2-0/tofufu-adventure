class_name DungeonInteractionTargets
extends RefCounted
## One state-aware focus choice drives both the prompt and the committed action.

static func selected(dungeon: TofuDungeon, actor: Player) -> Dictionary:
	if not is_instance_valid(actor) or not dungeon.actor_in_run(actor): return {}
	if dungeon.puzzle.phase not in [TofuPuzzleContract.Phase.READY, TofuPuzzleContract.Phase.OPERATING, TofuPuzzleContract.Phase.COMPLETE]: return {}
	var candidates: Array[Dictionary] = []
	var cargo: String = carried_id(dungeon, actor)
	if cargo.is_empty() and dungeon.puzzle.phase != TofuPuzzleContract.Phase.OPERATING:
		for id: String in TofuStashRules.IDS:
			if dungeon.stashes.available(id) and TofuFactory.room_at(TofuFactory.object_position(id)) <= dungeon.state.stage:
				candidates.append(_entry(id, TofuPuzzleCommand.Action.OPEN_STASH, "", "Open tucked-away chest"))
	match dungeon.puzzle.stage:
		TofuPuzzleContract.Stage.SORT: _sorting(dungeon, actor, cargo, candidates)
		TofuPuzzleContract.Stage.LAB: _lab(dungeon, actor, cargo, candidates)
		TofuPuzzleContract.Stage.PRESS:
			for id in ["traditional_press", "modern_press"]: candidates.append(_entry(id, -1, "", "Use " + id.replace("_", " ")))
		TofuPuzzleContract.Stage.CUT: candidates.append(_entry("cutter", -1, "", "Plan five cuts"))
		TofuPuzzleContract.Stage.PACK: _pack(dungeon, actor, cargo, candidates)
	var closest: Dictionary = {}
	var distance: float = DungeonPuzzleRuntime.INTERACTION_RANGE
	for candidate: Dictionary in candidates:
		var at: Vector3 = TofuFactory.object_position(candidate.id)
		if not at.is_finite() or TofuFactory.room_at(at) != TofuFactory.room_at(actor.global_position): continue
		var range: float = actor.global_position.distance_to(at)
		if range < distance and dungeon.puzzle_runtime._visible(actor, at):
			closest = candidate
			distance = range
	if closest.is_empty() and not cargo.is_empty():
		var object_id: String = cargo.trim_prefix("slab_") if cargo.begins_with("slab_") else ""
		return _entry(cargo, TofuPuzzleCommand.Action.RETURN_PROP, object_id, "Return " + cargo_name(dungeon, actor) + " to dock")
	return closest

static func carried_id(dungeon: TofuDungeon, actor: Player) -> String:
	var owner: int = DungeonMembership.actor_id(dungeon, actor)
	for id: String in dungeon.puzzle.sorting.carried_by:
		if dungeon.puzzle.sorting.carried_by[id] == owner: return id
	if dungeon.puzzle.lab.carrier_id == owner: return dungeon.puzzle.lab.carried_bottle
	for index in 6:
		if dungeon.puzzle.pack.owners[index] == owner: return "slab_%d" % index
	return ""

static func cargo_name(dungeon: TofuDungeon, actor: Player) -> String:
	var id: String = carried_id(dungeon, actor)
	if id.begins_with("container_"):
		return dungeon.puzzle.lab.content_at(id).replace("_", " ").capitalize() + " bottle"
	if id.begins_with("slab_"): return "tofu slab %d" % (int(id.trim_prefix("slab_")) + 1)
	return id.trim_prefix("sack_").replace("_", " ").capitalize() + " sack" if not id.is_empty() else ""

static func _sorting(dungeon: TofuDungeon, actor: Player, cargo: String, result: Array[Dictionary]) -> void:
	var sorting: TofuSortingRules = dungeon.puzzle.sorting
	if not cargo.is_empty():
		for id: String in TofuPuzzleContract.INTAKE_IDS:
			if not sorting.assignments.values().has(id): result.append(_inspect_or(dungeon, actor, id, TofuPuzzleCommand.Action.LOAD_INTAKE, cargo, "Load intake"))
	else:
		for id: String in TofuPuzzleContract.SACK_IDS:
			if not sorting.assignments.has(id) and not sorting.carried_by.has(id):
				result.append(_inspect_or(dungeon, actor, id, TofuPuzzleCommand.Action.PICK_UP, "", "Carry sack"))
		for id: String in TofuPuzzleContract.INTAKE_IDS: result.append(_entry(id, TofuPuzzleCommand.Action.INSPECT, "", "Inspect intake"))

static func _lab(dungeon: TofuDungeon, actor: Player, cargo: String, result: Array[Dictionary]) -> void:
	result.append(_entry("shift_note", TofuPuzzleCommand.Action.INSPECT, "", "Inspect folded paper"))
	result.append(_entry("lab_terminal", TofuPuzzleCommand.Action.OPEN_TERMINAL, "", "Use recipe terminal"))
	result.append(_entry("coagulation_tank", TofuPuzzleCommand.Action.POUR if not cargo.is_empty() else TofuPuzzleCommand.Action.INSPECT, cargo, "Pour into batch" if not cargo.is_empty() else "Inspect tank"))
	for index in 20:
		var id: String = "container_%02d" % index
		if id == dungeon.puzzle.lab.carried_bottle: continue
		var action: int = TofuPuzzleCommand.Action.PICK_UP if dungeon.puzzle.lab.carrier_id == 0 else TofuPuzzleCommand.Action.INSPECT
		result.append(_inspect_or(dungeon, actor, id, action, "", "Carry sealed bottle" if action == TofuPuzzleCommand.Action.PICK_UP else "Inspect bottle"))

static func _pack(dungeon: TofuDungeon, _actor: Player, cargo: String, result: Array[Dictionary]) -> void:
	var pack: TofuPackRules = dungeon.puzzle.pack
	for index in 6:
		if pack.slab_slots[index] < 0 and pack.owners[index] == 0 and cargo.is_empty():
			result.append(_entry("slab_%d" % index, TofuPuzzleCommand.Action.PICK_UP, str(index), "Carry slab %d" % (index + 1)))
		if pack.sealed[index]: continue
		if pack.slot_slabs[index] >= 0:
			result.append(_entry("package_%d" % index, TofuPuzzleCommand.Action.SEAL_SLOT, "", "Seal package %d" % (index + 1)))
		elif not cargo.is_empty(): result.append(_entry("package_%d" % index, TofuPuzzleCommand.Action.PLACE_SLAB, cargo.trim_prefix("slab_"), "Place slab in slot %d" % (index + 1)))

static func _inspect_or(dungeon: TofuDungeon, actor: Player, id: String, action: int, object_id: String, caption: String) -> Dictionary:
	var key: String = "%d:%s" % [DungeonMembership.actor_id(dungeon, actor), id]
	return _entry(id, action, object_id, caption) if dungeon.puzzle_flow.observed.has(key) else _entry(id, TofuPuzzleCommand.Action.INSPECT, "", "Inspect " + id.replace("_", " "))

static func _entry(id: String, action: int, object_id: String, caption: String) -> Dictionary:
	return {"id": id, "action": action, "object_id": object_id, "caption": caption}
