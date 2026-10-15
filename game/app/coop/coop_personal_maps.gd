class_name CoopPersonalMaps
extends Node
## Dedicated authority records exploration from real positions, never client claims.

var session: CoopSession
var maps: Dictionary[String, MapExploration] = {}
var _sent: Dictionary = {}
var _clock: float = 0
const MAP_PART_SIZE: int = 40000
var _incoming_revision: int = -1
var _applied_revision: int = -1
var _parts: Array[String] = ["", ""]

func _ready() -> void:
	if session.authority:
		for key: String in session.checkpoint.get("maps", {}):
			var map := MapExploration.new()
			map.restore(session.checkpoint.maps[key])
			maps[key] = map
	session.room.gameplay_packet.connect(_packet)

func _physics_process(delta: float) -> void:
	if not session.authority: return
	_clock += delta
	if _clock < 0.25: return
	_clock = 0
	for key: String in _sent.keys():
		if key not in session.room.members: _sent.erase(key)
	for key: String in session.roster.actors:
		if not maps.has(key): maps[key] = MapExploration.new()
		var at: Vector3 = session.roster.actors[key].position
		if TofuFactory.contains(at): at = TofuFactory.EAST_ENTRANCE
		maps[key].reveal(Vector2(at.x, at.z))
		if session._ready_peers.has(key) and not _sent.has(key):
			_sent[key] = true
			_send_map(key)

func _send_map(key: String) -> void:
	var mask := maps[key].capture()
	if mask.length() <= MAP_PART_SIZE:
		session.room.send_game(key, {"type": "personal_map", "mask": mask})
		return
	for part in 2:
		session.room.send_game(key, {"type": "personal_map", "revision": maps[key].revision,
			"part": part, "parts": 2, "mask": mask.substr(part * MAP_PART_SIZE, MAP_PART_SIZE)})

func _packet(key: String, data: Dictionary) -> void:
	if session.authority or key != session.room.host_key or data.get("type") != "personal_map": return
	if not data.has("parts"):
		if MapSaveValidation.valid(data.get("mask")): session.game.map.restore_exploration(data.mask)
		return
	if data.get("parts") != 2 or not ExplorationProtocol.sequence(data.get("part")) or data.part > 1: return
	if not ExplorationProtocol.sequence(data.get("revision")) or data.revision <= _applied_revision: return
	if not data.get("mask") is String or data.mask.is_empty() or data.mask.length() > MAP_PART_SIZE: return
	var revision := int(data.revision)
	if revision < _incoming_revision: return
	if revision > _incoming_revision:
		_incoming_revision = revision
		_parts = ["", ""]
	_parts[int(data.part)] = data.mask
	if _parts[0].is_empty() or _parts[1].is_empty(): return
	var mask := _parts[0] + _parts[1]
	if not MapSaveValidation.valid(mask): return
	_applied_revision = revision
	_parts = ["", ""]
	session.game.map.restore_exploration(mask)

func capture() -> Dictionary:
	var result := {}
	for key: String in maps: result[key] = maps[key].capture()
	return result
