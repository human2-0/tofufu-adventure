class_name PublicCharacters
extends RefCounted
## Server-owned unique names and credential digests. Never stores raw credentials.

var path: String = "/var/lib/tofufu/characters.json"
var records: Dictionary = {}
var error: String = ""
var _last_creation: int = -10000

static func valid_name(value: Variant) -> bool:
	return value is String and RegEx.create_from_string("^[A-Za-z][A-Za-z0-9_]{2,19}$").search(value) != null

static func hex_key(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if character not in "0123456789abcdef": return false
	return true

func load_records() -> bool:
	records.clear()
	if not FileAccess.file_exists(path): return true
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 16384: return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return false
	var data: Variant = parser.data
	if not data is Dictionary or data.get("version") != 1 or not data.get("characters") is Dictionary: return false
	if data.characters.size() > 32: return false
	var names: Array[String] = []
	for key: Variant in data.characters:
		var name: Variant = data.characters[key]
		if not hex_key(key) or not valid_name(name) or name.to_lower() in names: return false
		names.append(name.to_lower())
	records = data.characters
	return true

func admit(token: String, name: String, create: bool) -> String:
	error = ""
	var identity := token.sha256_text()
	if records.has(identity):
		if records[identity] != name:
			error = "Use the character name saved on this device."
			return ""
		return identity
	if not create or not valid_name(name):
		error = "Choose 3–20 letters, numbers or underscores, starting with a letter."
		return ""
	for existing: String in records.values():
		if existing.to_lower() == name.to_lower():
			error = "That character name is already taken. Choose another."
			return ""
	if records.size() >= 32:
		error = "All 32 test character places are reserved. Contact the server owner."
		return ""
	var now := Time.get_ticks_msec()
	if now - _last_creation < 2000:
		error = "Character creation is busy. Try again in a few seconds."
		return ""
	_last_creation = now
	records[identity] = name
	if not _save():
		records.erase(identity)
		error = "The server could not save your character. Try again later."
		return ""
	return identity

func _save() -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"version": 1, "characters": records}))
	file.flush()
	var success := file.get_error() == OK
	file.close()
	return success and DirAccess.rename_absolute(path + ".tmp", path) == OK
