class_name TofuPackRules
extends RefCounted
## Six unique quest slabs transfer to six slots, each sealed once.

enum Outcome { INVALID, RESERVED, PLACED, SEALED, BOSS_READY }

const COUNT: int = 6

var revision: int = 0
var batch_id: String = ""
var slab_slots: Array[int] = [-1, -1, -1, -1, -1, -1]
var slot_slabs: Array[int] = [-1, -1, -1, -1, -1, -1]
var sealed: Array[bool] = [false, false, false, false, false, false]
var owners: Array[int] = [0, 0, 0, 0, 0, 0]
var boss_ready: bool = false

func begin_batch(id: String) -> bool:
	if not batch_id.is_empty() or id.is_empty(): return false
	batch_id = id
	revision += 1
	return true

func slab_id(index: int) -> String:
	return "%s_slab_%d" % [batch_id, index] if _index(index) and not batch_id.is_empty() else ""

func reserve(slab: int, actor: int, expected: int) -> Outcome:
	if not _valid(slab, expected) or actor < 1 or owners[slab] != 0 or slab_slots[slab] != -1 or owners.has(actor): return Outcome.INVALID
	owners[slab] = actor
	revision += 1
	return Outcome.RESERVED

func place(slab: int, slot: int, actor: int, expected: int) -> Outcome:
	if not _valid(slab, expected) or not _index(slot) or actor < 1: return Outcome.INVALID
	if owners[slab] != actor or slab_slots[slab] != -1 or slot_slabs[slot] != -1: return Outcome.INVALID
	slab_slots[slab] = slot
	slot_slabs[slot] = slab
	owners[slab] = 0
	revision += 1
	return Outcome.PLACED

func seal(slot: int, expected: int) -> Outcome:
	if not _index(slot) or expected != revision or slot_slabs[slot] < 0 or sealed[slot]: return Outcome.INVALID
	sealed[slot] = true
	revision += 1
	if sealed.all(func(value: bool) -> bool: return value):
		boss_ready = true
		return Outcome.BOSS_READY
	return Outcome.SEALED

func release_actor(actor: int) -> void:
	if actor < 1: return
	for index in COUNT:
		if owners[index] == actor:
			owners[index] = 0
			revision += 1

func return_slab(slab: int, actor: int, expected: int) -> Outcome:
	if not _valid(slab, expected) or actor < 1 or owners[slab] != actor: return Outcome.INVALID
	owners[slab] = 0
	revision += 1
	return Outcome.RESERVED

func capture(live: bool = false) -> Dictionary:
	var data: Dictionary = {"revision": revision, "batch_id": batch_id, "slab_slots": slab_slots.duplicate(), "slot_slabs": slot_slabs.duplicate(), "sealed": sealed.duplicate(), "boss_ready": boss_ready}

	if live: data["owners"] = owners.duplicate()
	return data

func restore(data: Dictionary, live: bool = false) -> bool:
	var slabs: Variant = data.get("slab_slots", [])
	var slots: Variant = data.get("slot_slabs", [])
	var seals: Variant = data.get("sealed", [])
	if not TofuPuzzleContract.bounded_integer(data.get("revision"), 0, 2147483646): return false
	if not data.get("batch_id") is String or data.batch_id.length() > 160: return false
	if not data.get("boss_ready", false) is bool: return false
	var saved_revision: int = int(data.revision)
	var saved_batch: String = data.batch_id
	var saved_owners: Variant = data.get("owners", [0, 0, 0, 0, 0, 0])
	if not saved_owners is Array or saved_owners.size() != COUNT: return false
	var checked_owners: Array[int] = []
	for owner: Variant in saved_owners:
		if not TofuPuzzleContract.bounded_integer(owner, 0, 2147483647): return false
		if int(owner) != 0 and checked_owners.has(int(owner)): return false
		checked_owners.append(int(owner))
	if saved_revision < 0 or not slabs is Array or not slots is Array or not seals is Array: return false
	if slabs.size() != COUNT or slots.size() != COUNT or seals.size() != COUNT: return false
	for index in COUNT:
		if not TofuPuzzleContract.bounded_integer(slabs[index], -1, COUNT - 1): return false
		if not TofuPuzzleContract.bounded_integer(slots[index], -1, COUNT - 1) or not seals[index] is bool: return false
		if int(slabs[index]) < -1 or int(slabs[index]) >= COUNT or int(slots[index]) < -1 or int(slots[index]) >= COUNT: return false
		if int(slabs[index]) >= 0 and int(slots[int(slabs[index])]) != index: return false
		if int(slots[index]) >= 0 and int(slabs[int(slots[index])]) != index: return false
		if bool(seals[index]) and int(slots[index]) < 0: return false
		if checked_owners[index] > 0 and (saved_batch.is_empty() or int(slabs[index]) != -1): return false
	if saved_batch.is_empty():
		for index in COUNT:
			if int(slabs[index]) != -1 or int(slots[index]) != -1 or bool(seals[index]): return false
	var all_sealed: bool = true
	for value: Variant in seals: all_sealed = all_sealed and bool(value)
	if bool(data.get("boss_ready", false)) != all_sealed: return false
	revision = saved_revision + (0 if live else 1)
	batch_id = saved_batch
	slab_slots.clear()
	slot_slabs.clear()
	for value: Variant in slabs: slab_slots.append(int(value))
	for value: Variant in slots: slot_slabs.append(int(value))
	sealed.assign(seals)
	owners.assign(checked_owners if live else [0, 0, 0, 0, 0, 0])
	boss_ready = all_sealed
	return true

func _valid(index: int, expected: int) -> bool:
	return _index(index) and expected == revision and not batch_id.is_empty() and not boss_ready

func _index(value: int) -> bool:
	return value >= 0 and value < COUNT
