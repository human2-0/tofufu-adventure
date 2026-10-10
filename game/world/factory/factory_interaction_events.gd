class_name FactoryInteractionEvents
extends RefCounted
## Edges of confirmed state changes only. Loading a checkpoint is a silent baseline.

var room: int = 0
var _identity: String = ""
var _previous: Dictionary = {}

func collect(snapshot: Dictionary) -> Array[Dictionary]:
	var identity: String = "%s:%s" % [snapshot.get("run_id", 0), snapshot.get("attempt_id", 0)]
	var field: String = ["sorting", "lab", "press", "cut", "pack", "boss"][room]
	var data: Dictionary = snapshot.get(field, {})
	var events: Array[Dictionary] = []
	if needs_baseline(snapshot):
		_identity = identity
		_previous = data.duplicate(true)
		return events
	if _edge_key(data) == _edge_key(_previous): return events
	match room:
		0: _sorting(data, events)
		1: _lab(data, events)
		2: _press(data, events)
		3:
			if _rose(data, "completed") or _rose(data, "rejected"):
				_add(events, "crumbs", "cutter", Vector3(0, 1.5, 0))
		4: _pack(data, events)
	_previous = data.duplicate(true)
	return events

func needs_baseline(snapshot: Dictionary) -> bool:
	var identity: String = "%s:%s" % [snapshot.get("run_id", 0), snapshot.get("attempt_id", 0)]
	var field: String = ["sorting", "lab", "press", "cut", "pack", "boss"][room]
	var data: Dictionary = snapshot.get(field, {})
	return identity != _identity or _previous.is_empty() or int(data.get("revision", 0)) < int(_previous.get("revision", 0))

func _sorting(data: Dictionary, events: Array[Dictionary]) -> void:
	var carried: Dictionary = data.get("carried_by", {})
	var old_carried: Dictionary = _previous.get("carried_by", {})
	var assignments: Dictionary = data.get("assignments", {})
	var old_assignments: Dictionary = _previous.get("assignments", {})
	for id: String in FactoryLayout.SACK_IDS:
		if carried.has(id) != old_carried.has(id):
			_add(events, "dust", id, Vector3(0, 0.12, 0))
		if assignments.has(id) and not old_assignments.has(id):
			_add(events, "beans", str(assignments[id]), Vector3(0, 1.55, 0.3))
		if _rose(data, "combat_locked") and old_carried.has(id) and not carried.has(id):
			_add(events, "reject", id, Vector3(0, 0.45, 0))

func _lab(data: Dictionary, events: Array[Dictionary]) -> void:
	var old_bottle: String = str(_previous.get("carried_bottle", ""))
	var bottle: String = str(data.get("carried_bottle", ""))
	if bottle != old_bottle and not bottle.is_empty():
		_add(events, "mist", bottle, Vector3(0, 0.25, 0))
	if not old_bottle.is_empty() and bottle.is_empty():
		if _rose(data, "complete") or _rose(data, "curd_encounter") or _rose(data, "combat_locked"):
			_add(events, "pour", "coagulation_tank", Vector3(-0.4, 1.65, 0))
			events.back()["source"] = old_bottle
		else: _add(events, "mist", old_bottle, Vector3(0, 0.1, 0))
	if _rose(data, "combat_locked"):
		_add(events, "reject", "coagulation_tank", Vector3(0, 1.7, 0))
	if _rose(data, "complete"):
		_add(events, "steam", "coagulation_tank", Vector3(0, 1.7, 0))
	if bool(_previous.get("combat_locked", false)) and not bool(data.get("combat_locked", false)):
		_add(events, "pour", "coagulation_tank", Vector3(-0.8, 1.7, 0))

func _press(data: Dictionary, events: Array[Dictionary]) -> void:
	var stones: Array = data.get("stones", [])
	var old_stones: Array = _previous.get("stones", [])
	for id: String in stones:
		if not old_stones.has(id): _add(events, "dust", "traditional_press", Vector3(0, 1.15, 0))
	var sample: int = int(data.get("active_sample", -1))
	if sample >= 0 and int(_previous.get("active_sample", -1)) < 0:
		_add(events, "steam", "modern_press" if sample == 2 else "traditional_press", Vector3(0, 0.8, 0.8))
	var flags: Array = data.get("certificates", [])
	var old_flags: Array = _previous.get("certificates", [])
	for index in mini(flags.size(), old_flags.size()):
		if bool(flags[index]) and not bool(old_flags[index]):
			_add(events, "steam", "modern_press" if index == 2 else "traditional_press", Vector3(0, 0.8, 0.8))
	if _rose(data, "rejected"):
		var old_sample: int = int(_previous.get("active_sample", -1))
		_add(events, "reject", "modern_press" if old_sample == 2 else "traditional_press", Vector3(0, 0.8, 0.8))

func _pack(data: Dictionary, events: Array[Dictionary]) -> void:
	var slots: Array = data.get("slot_slabs", [])
	var old_slots: Array = _previous.get("slot_slabs", [])
	var seals: Array = data.get("sealed", [])
	var old_seals: Array = _previous.get("sealed", [])
	for index in mini(slots.size(), old_slots.size()):
		if int(slots[index]) >= 0 and int(old_slots[index]) < 0:
			_add(events, "crumbs", "package_%d" % index, Vector3(0, 0.2, 0))
	for index in mini(seals.size(), old_seals.size()):
		if bool(seals[index]) and not bool(old_seals[index]):
			_add(events, "steam", "package_%d" % index, Vector3(0, 0.32, 0))

func _rose(data: Dictionary, field: String) -> bool:
	return bool(data.get(field, false)) and not bool(_previous.get(field, false))

func _edge_key(data: Dictionary) -> String:
	return "%s:%s:%s:%s:%s" % [data.get("revision", 0), data.get("combat_locked", false), data.get("opening_cleared", false), data.get("complete", false), data.get("curd_encounter", false)]

func _add(events: Array[Dictionary], kind: String, target: String, offset: Vector3) -> void:
	events.append({"kind": kind, "target": target, "offset": offset})
