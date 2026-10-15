class_name CoopStatAllocation
extends Node
## Stat buttons submit bounded intent; authority spends each character's own points.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary = {}
var _pending: Dictionary = {}

func _ready() -> void:
	var direct: Callable = session.game.progression.progress.allocate_stat
	if session.game.hud.stat_point_allocated.is_connected(direct):
		session.game.hud.stat_point_allocated.disconnect(direct)
	session.game.hud.stat_point_allocated.connect(request)
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_members_changed)

func request(skill: String) -> void:
	_sequence += 1
	var data := {"type": "allocate_stat", "skill": skill, "sequence": _sequence}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority or data.get("type") != "allocate_stat" or not session.roster.party.has(key): return
	if session.duel.is_participant(key) or session.opening.active(): return
	if not data.get("skill") is String or data.skill not in CharacterProgress.SKILLS: return
	if not ExplorationProtocol.sequence(data.get("sequence")): return
	var last: int = int(_seen.get(key, 0))
	if data.sequence <= last or data.sequence > last + 240: return
	_seen[key] = int(data.sequence)
	if not _pending.has(key): _pending[key] = []
	if _pending[key].size() < 8: _pending[key].append(data.skill)

func _physics_process(_delta: float) -> void:
	for key: String in _pending:
		if not session.roster.party.has(key) or session.duel.is_participant(key): continue
		var progress: CharacterProgress = session.roster.party[key].progression.progress
		for skill: String in _pending[key]: progress.allocate_stat(skill)
	_pending.clear()

func _members_changed() -> void:
	for key: String in _seen.keys():
		if key not in session.room.members:
			_seen.erase(key)
			_pending.erase(key)
