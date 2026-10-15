class_name PublicProfile
extends RefCounted
## A passwordless test character is bound to an automatically saved device secret.

const ENDPOINT: String = "wss://79.72.79.130/tofufu-adventure/play"
var path: String = "user://public-character.json"
var data: Dictionary = {}
var error: String = ""

func load_profile() -> bool:
	data.clear()
	error = ""
	if not FileAccess.file_exists(path): return true
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null and file.get_length() <= 2048:
		var parser := JSON.new()
		if parser.parse(file.get_as_text()) == OK:
			var value: Variant = parser.data
			if value is Dictionary and value.get("registered", false) is bool and PublicCharacters.hex_key(value.get("token")) and PublicCharacters.valid_name(value.get("name")):
				data = value
				return true
	error = "Your saved character key is unreadable. Restore its backup to recover your character."
	return false

func prepare(name: String) -> bool:
	if not PublicCharacters.valid_name(name):
		error = "Use 3–20 letters, numbers or underscores, starting with a letter."
		return false
	if data.get("registered", false) and data.get("name") != name:
		error = "Use the character name saved on this device."
		return false
	var token: String = str(data.get("token", ""))
	if token.is_empty(): token = Crypto.new().generate_random_bytes(32).hex_encode()
	var next := {"token": token, "name": name, "registered": data.get("registered", false)}
	return _save(next)

func confirm() -> bool:
	var next := data.duplicate()
	next.registered = true
	return _save(next)

func _save(next: Dictionary) -> bool:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = "Could not save your character key on this device. Check disk space."
		return false
	if OS.get_name() in ["macOS", "Linux"]:
		if OS.execute("chmod", PackedStringArray(["600", ProjectSettings.globalize_path(path + ".tmp")])) != 0:
			file.close()
			error = "Could not make your saved character key private."
			return false
	file.store_string(JSON.stringify(next))
	file.flush()
	var success := file.get_error() == OK
	file.close()
	if not success or DirAccess.rename_absolute(path + ".tmp", path) != OK:
		error = "Could not finish saving your character key."
		return false
	data = next
	error = ""
	return true
