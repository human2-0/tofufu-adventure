class_name SaveStore
extends RefCounted
## Versioned value records, bounded reads and atomic slot replacement.

var directory: String = "user://adventures"
var extra_validator: Callable
var last_error: String = ""
const MAX_SLOTS: int = 12

func list_saves() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in MAX_SLOTS:
		if FileAccess.file_exists(_path(slot)):
			var data := read_slot(slot)
			result.append({"slot": slot, "data": data, "valid": not data.is_empty()})
	return result

func free_slot() -> int:
	for slot in MAX_SLOTS:
		if not FileAccess.file_exists(_path(slot)):
			return slot
	return -1

func write_slot(slot: int, data: Dictionary) -> bool:
	last_error = ""
	if slot < 0 or slot >= MAX_SLOTS or not record_valid(data):
		last_error = "This adventure could not be saved: invalid state."
		return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		last_error = "Could not create the save folder."
		return false
	var file := FileAccess.open(_path(slot) + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Could not write the save. Check available disk space."
		return false
	var encoded := JSON.stringify(data)
	if encoded.to_utf8_buffer().size() > 65536:
		file.close()
		last_error = "This adventure exceeds the save size limit."
		return false
	file.store_string(encoded)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(_path(slot) + ".tmp", _path(slot)) != OK:
		last_error = "Could not finish saving. Your previous save is still available."
		return false
	return true

func read_slot(slot: int) -> Dictionary:
	if slot < 0 or slot >= MAX_SLOTS:
		return {}
	var file := FileAccess.open(_path(slot), FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary and record_valid(data) else {}

func remove_slot(slot: int) -> bool:
	return slot >= 0 and slot < MAX_SLOTS and DirAccess.remove_absolute(_path(slot)) == OK

func _path(slot: int) -> String:
	return directory.path_join("adventure_%02d.json" % slot)

static func valid(data: Dictionary) -> bool:
	if data.has("coins") and (not _progress_counter(data.coins) or data.coins > 1000000): return false
	if data.has("active_slot") and (not _progress_counter(data.active_slot) or data.active_slot < 1 or data.active_slot > 2): return false
	if data.has("world_items") and not _world_items(data.world_items): return false
	for field in ["gun_owned", "sotjet_owned"]:
		if data.has(field) and not data[field] is bool: return false
	if data.get("version") != 1 or not data.get("name") is String or not data.get("saved_at") is String:
		return false
	if data.name.length() > 48 or not data.get("opening_complete") is bool:
		return false
	for field in ["position", "dropped_position"]:
		if not data.get(field) is Array or data[field].size() != 3:
			return false
		for value: Variant in data[field]:
			if not (value is float or value is int) or not is_finite(float(value)) or absf(float(value)) > 500:
				return false
	for field in ["health", "phase", "beans", "mobs", "props", "experience", "seconds"]:
		var value: Variant = data.get(field)
		if not (value is float or value is int) or not is_finite(float(value)) or value < 0 or value > 100000000:
			return false
	if data.has("sotjet_selected") and not data.sotjet_selected is bool: return false
	if data.has("soymilk"):
		var milk: Variant = data.soymilk
		if not (milk is float or milk is int) or not is_finite(float(milk)) or milk < 0 or milk > 100: return false
	if data.get("sotjet_selected", false) and (data.get("gun_selected", false) or data.get("knife_selected", false)): return false
	if data.has("gun_selected") and not data.gun_selected is bool: return false
	if data.get("gun_selected", false) and data.get("knife_selected", false): return false
	if data.has("progression") and not progression(data.progression): return false
	if data.has("weather_phase"):
		var weather: Variant = data.weather_phase
		if not (weather is float or weather is int) or not is_finite(float(weather)) or weather < 0 or weather > 1: return false
	if data.health > 100 or data.phase > 1:
		return false
	if not data.get("knife_owned") is bool or not data.get("knife_selected") is bool:
		return false
	if not data.get("discoveries") is Array or data.discoveries.size() > 4:
		return false
	for item: Variant in data.discoveries:
		if not item is String or item.length() > 80:
			return false
	return true

func record_valid(data: Dictionary) -> bool:
	if not valid(data): return false
	if not data.has("coop"): return true
	return data.coop is Dictionary and extra_validator.is_valid() and extra_validator.call(data.coop)

static func progression(value: Variant) -> bool:
	if not value is Dictionary: return false
	var ver: Variant = value.get("version")
	if not _progress_counter(ver) or ver < 1 or ver > 2: return false
	var xp: Variant = value.get("experience")
	if not _progress_counter(xp): return false
	var practice: Variant = value.get("practice")
	if not practice is Dictionary or practice.size() not in [5, 6]: return false
	for field in ["fist", "sword", "magic", "attack_speed", "defence"]:
		if not _progress_counter(practice.get(field)): return false
	if practice.size() == 6 and not _progress_counter(practice.get("shooting")): return false
	if ver == 2:
		if value.has("stat_points") and not _progress_counter(value.get("stat_points")): return false
		if value.has("granted_level") and not _progress_counter(value.get("granted_level")): return false
		if value.has("stats"):
			var st: Variant = value.get("stats")
			if not st is Dictionary: return false
			for field: Variant in st.values():
				if not _progress_counter(field): return false
	return true

static func _progress_counter(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 100000000 and float(value) == floorf(value)

static func _world_items(value: Variant) -> bool:
	if not value is Array or value.size() > 128: return false
	var ids: Array[int] = []
	for row: Variant in value:
		if not row is Array or row.size() != 7: return false
		if not _progress_counter(row[0]) or row[0] < 1 or int(row[0]) in ids: return false
		ids.append(int(row[0]))
		if not row[1] is String or row[1] not in ["knife", "soy_gun", "sotjet", "soybean"]: return false
		if not _progress_counter(row[2]) or row[2] < 1 or row[2] > (999 if row[1] == "soybean" else 1): return false
		for index in range(3, 7):
			var number: Variant = row[index]
			if not (number is float or number is int) or not is_finite(float(number)) or absf(number) > (100 if index == 3 else 500): return false
		if row[3] < 0: return false
	return true
