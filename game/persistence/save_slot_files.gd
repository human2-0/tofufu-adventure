class_name SaveSlotFiles
extends RefCounted
## Mode folders share slot numbers; legacy records are read without rewriting them.

static func path(directory: String, mode: String, slot: int) -> String:
	var folder := directory if mode.is_empty() else directory.path_join(mode)
	return folder.path_join("adventure_%02d.json" % slot)

static func read(pathname: String, limit: int) -> Dictionary:
	var file := FileAccess.open(pathname, FileAccess.READ)
	if file == null or file.get_length() > limit: return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}

static func matches(data: Dictionary, mode: String) -> bool:
	return mode.is_empty() or (not data.is_empty() and data.has("coop") == (mode == "coop"))

static func existing(directory: String, mode: String, slot: int, limit: int) -> String:
	var current := path(directory, mode, slot)
	if FileAccess.file_exists(current): return current
	if not mode.is_empty():
		var legacy := path(directory, "", slot)
		if FileAccess.file_exists(legacy) and matches(read(legacy, limit), mode): return legacy
	return ""

static func remove(directory: String, mode: String, slot: int, limit: int) -> bool:
	var current := existing(directory, mode, slot, limit)
	if current.is_empty(): return false
	if DirAccess.remove_absolute(current) != OK: return false
	# A copied legacy record must not reappear after deleting its current slot.
	var legacy := path(directory, "", slot)
	if current != legacy and FileAccess.file_exists(legacy) and matches(read(legacy, limit), mode):
		return DirAccess.remove_absolute(legacy) == OK
	return true

static func write(pathname: String, data: Dictionary, limit: int) -> String:
	var encoded := JSON.stringify(data)
	if encoded.to_utf8_buffer().size() > limit:
		return "This adventure exceeds the save size limit."
	if DirAccess.make_dir_recursive_absolute(pathname.get_base_dir()) != OK:
		return "Could not create the save folder."
	var temporary := pathname + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return "Could not write the save. Check available disk space."
	file.store_string(encoded)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(temporary, pathname) != OK:
		DirAccess.remove_absolute(temporary)
		return "Could not finish saving. Your previous save is still available."
	return ""
