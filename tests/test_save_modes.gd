extends SceneTree
## Atomic storage, old mixed slots, mode isolation and the celestial save regression.

var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var directory := "user://save-modes-%d" % Time.get_ticks_usec()
	var legacy := SaveStore.new()
	legacy.directory = directory
	legacy.extra_validator = func(_data: Dictionary) -> bool: return true
	var solo := SaveStore.new()
	solo.directory = directory
	solo.mode = "solo"
	var coop := SaveStore.new()
	coop.directory = directory
	coop.mode = "coop"
	coop.size_limit = 4194304
	coop.extra_validator = legacy.extra_validator
	var record := fixture()
	var shared := record.duplicate(true)
	shared.coop = {"version": 2}
	check(legacy.write_slot(0, record) and legacy.write_slot(1, shared), "legacy mixed records write")
	var original := FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "", 1))
	check(solo.list_saves().size() == 1 and coop.list_saves().size() == 1, "legacy records appear only in their original mode")
	check(solo.read_slot(1).is_empty() and coop.read_slot(0).is_empty(), "cross-mode legacy reads refused")
	check(solo.free_slot() == 1 and coop.free_slot() == 0, "each mode has its own free slots")
	check(not solo.write_slot(0, shared) and not coop.write_slot(0, record), "cross-mode writes refused")
	check(coop.write_slot(1, shared), "legacy shared save continues in co-op folder")
	check(FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "", 1)) == original, "legacy file remains byte-for-byte safe after resaving")
	check(coop.list_saves().size() == 1, "resaved legacy adventure listed once")
	check(solo.write_slot(1, record), "solo can use the same slot number as co-op")
	check(coop.remove_slot(1) and coop.list_saves().is_empty(), "deleting a migrated save cannot resurrect legacy copy")
	check(not solo.read_slot(1).is_empty(), "co-op deletion keeps same-number solo save")
	check(SaveStore.WORLD_ITEM_LIMITS == WorldProtocol.ITEM_LIMITS, "disk and live item limits cover the same equipment")
	for id: String in CelestialItems.IDS:
		var dropped := fixture()
		dropped.world_items = [[1, id, 1, 100, 0, 0, 0]]
		check(solo.write_slot(2, dropped), "celestial drop saves: " + id)
		dropped.world_items = [[1, "traveler_backpack", 1, 100, 0, 0, 0, [{"id": id, "count": 1}]]]
		check(solo.write_slot(2, dropped), "celestial backpack contents save: " + id)
		var chests: Array = []
		var owners: Array = []
		for bay in 20:
			var slots: Array = []
			for slot in 24: slots.append({})
			chests.append(slots)
			owners.append("solo" if bay == 0 else "")
		chests[0][0] = {"id": id, "count": 1}
		dropped.barn = {"owners": owners, "chests": chests}
		check(solo.write_slot(2, dropped), "celestial barn deposit saves: " + id)
	var invalid := fixture()
	invalid.world_items = [[1, "celestial_sword", 2, 100, 0, 0, 0]]
	var previous := FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "solo", 2))
	check(not solo.write_slot(2, invalid), "invalid celestial stack still rejected")
	check(previous == FileAccess.get_file_as_bytes(SaveSlotFiles.path(directory, "solo", 2)), "invalid save cannot replace previous file")
	for slot in 3: solo.remove_slot(slot)
	for mode in ["solo", "coop"]: DirAccess.remove_absolute(directory.path_join(mode))
	DirAccess.remove_absolute(directory)
	print("Save modes: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

static func fixture() -> Dictionary:
	return {"version": 1, "name": "Save test", "saved_at": "now", "opening_complete": true,
		"position": [0, 0, 0], "dropped_position": [0, 0, 0], "health": 100,
		"phase": 0, "seconds": 0, "beans": 0, "mobs": 0, "props": 0, "experience": 0,
		"discoveries": [], "knife_owned": true, "knife_selected": true}
