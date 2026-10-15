class_name OracleAdmission
extends RefCounted
## Validates configured identities and public name claims before room admission.

var characters := PublicCharacters.new()
var public_registration: bool = false
var error: String = ""

func configure(config: Dictionary) -> bool:
	public_registration = config.get("public_registration", false) == true
	if not PublicCharacters.hex_key(config.get("server_id")) or not config.get("players") is Array: return false
	if config.players.size() > 32 or (config.players.is_empty() and not public_registration): return false
	for identity: Variant in config.players:
		if not PublicCharacters.hex_key(identity) or identity == config.server_id: return false
	if public_registration:
		var directory := OS.get_environment("TOFUFU_STATE_DIR") if OS.has_environment("TOFUFU_STATE_DIR") else "/var/lib/tofufu"
		characters.path = str(config.get("characters_file", directory.path_join("characters.json")))
		return characters.load_records()
	return true

func authenticate(config: Dictionary, data: Dictionary) -> Dictionary:
	error = "Invalid connection credentials."
	if not PublicCharacters.hex_key(data.get("auth")) or not data.get("name") is String: return {}
	var identity: String = str(data.auth).sha256_text()
	if identity == config.server_id: return {}
	if public_registration and data.get("public") == true:
		identity = characters.admit(data.auth, data.name, data.get("create") == true)
		error = characters.error
		if identity.is_empty(): return {}
		return {"identity": identity, "name": characters.records[identity]}
	if not config.players.has(identity): return {}
	return {"identity": identity, "name": str(data.name).left(24)}
