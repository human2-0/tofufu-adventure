class_name BattleCareer
extends RefCounted
## Local cosmetic records, isolated from adventure saves and all match equipment.

var path: String = "user://battle_royale_career.json"
var xp: int = 0
var totals: Dictionary = {"practice": [0, 0, 0, 0], "peers": [0, 0, 0, 0]}
var claimed: Array = []

func load_records() -> void:
	for source in [path, path + ".bak"]:
		var data := _read(source)
		if data.is_empty(): continue
		_apply(data)
		return

func award(epoch: String, summary: Dictionary, practice: bool) -> bool:
	if not BattleProtocol.token(epoch) or claimed.has(epoch) or int(summary.rank) <= 0: return false
	var before := _values()
	xp = mini(100000000, xp + int(summary.xp))
	var row: Array = totals["practice" if practice else "peers"]
	row[0] = mini(1000000, int(row[0]) + 1)
	row[1] = mini(1000000, int(row[1]) + int(summary.won))
	row[2] = mini(100000000, int(row[2]) + int(summary.kills))
	row[3] = mini(100000000, int(row[3]) + int(summary.damage))
	claimed.append(epoch)
	if claimed.size() > 64: claimed.pop_front()
	if _save(): return true
	_apply(before)
	return false

func caption(projected_xp: int = 0) -> String:
	var total := mini(100000000, xp + maxi(0, projected_xp))
	var level := 1 + floori(sqrt(float(total) / 100))
	var lower := (level - 1) * (level - 1) * 100
	return tr("Royale level %d · %d / %d XP") % [level, total - lower, level * level * 100 - lower]

func records() -> String:
	return tr("Practice: %d rounds · %d wins | Peers: %d rounds · %d wins") % [totals.practice[0], totals.practice[1], totals.peers[0], totals.peers[1]]

func _values() -> Dictionary:
	return {"version": 1, "xp": xp, "totals": totals.duplicate(true), "claimed": claimed.duplicate()}

func _apply(data: Dictionary) -> void:
	xp = int(data.xp)
	totals = data.totals.duplicate(true)
	claimed = data.claimed.duplicate()

func _save() -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(_values()))
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	if not ok: return false
	if not _read(path).is_empty():
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak")) != OK: return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK

func _read(source: String) -> Dictionary:
	if not FileAccess.file_exists(source): return {}
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null or file.get_length() > 32768: return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	return parser.data if _valid(parser.data) else {}

func _valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != 1 or not BattleProtocol.integer(data.get("xp"), 0, 100000000): return false
	if not data.get("totals") is Dictionary or not data.get("claimed") is Array or data.claimed.size() > 64: return false
	for category in ["practice", "peers"]:
		var row: Variant = data.totals.get(category)
		if not row is Array or row.size() != 4: return false
		for value: Variant in row:
			if not BattleProtocol.integer(value, 0, 100000000): return false
		if row[0] > 1000000 or row[1] > row[0]: return false
	var seen: Dictionary = {}
	for id: Variant in data.claimed:
		if not BattleProtocol.token(id) or seen.has(id): return false
		seen[id] = true
	return true
