class_name CoopFarming
extends Node
## Host/server owns growth and rewards; guests submit bounded revisioned intents.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary = {}
var _pending: Dictionary = {}
var _last_result: int = -1

func _ready() -> void:
	session.game.farming.authoritative = session.authority
	session.game.farming.request_action = request
	session.game.farming.simulation_enabled = func() -> bool: return session.room.playing and not session.opening.active()
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_members_changed)

func request(id: int, revision: int, action: String) -> void:
	_sequence += 1
	var data := {"type": "farm_action", "sequence": _sequence, "plot": id, "revision": revision, "action": action}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority:
		if key != session.room.host_key or data.get("type") != "farm_result": return
		if not ExplorationProtocol.sequence(data.get("sequence")) or data.sequence <= _last_result or data.sequence > _sequence: return
		if not data.get("message") is String or data.message.length() > 160: return
		_last_result = int(data.sequence)
		session.game.hud.announce(data.message)
		return
	if data.get("type") != "farm_action" or not session.room.playing or session.opening.active(): return
	if not session.roster.party.has(key): return
	if not ExplorationProtocol.sequence(data.get("sequence")) or data.sequence <= _seen.get(key, -1): return
	if not ExplorationProtocol.sequence(data.get("plot")) or data.plot >= 4: return
	if not ExplorationProtocol.sequence(data.get("revision")) or data.get("action") not in ["plant", "harvest"]: return
	_seen[key] = int(data.sequence)
	# At most one intent per member per physics tick, without an unbounded queue.
	_pending[key] = data.duplicate()

func _physics_process(_delta: float) -> void:
	for key: String in _pending:
		if not session.room.playing or session.opening.active() or not session.roster.party.has(key): continue
		var member: CoopActor = session.roster.party[key]
		if member.health.current <= 0: continue
		var data: Dictionary = _pending[key]
		var message: String = session.game.farming.perform(member.actor, member.inventory, int(data.plot), int(data.revision), data.action)
		if message.is_empty(): continue
		if key == session.room.local_key: session.game.hud.announce(message)
		else: session.room.send_game(key, {"type": "farm_result", "sequence": data.sequence, "message": message})
	_pending.clear()

func _members_changed() -> void:
	for key: String in _seen.keys():
		if not session.roster.party.has(key):
			_seen.erase(key)
			_pending.erase(key)
