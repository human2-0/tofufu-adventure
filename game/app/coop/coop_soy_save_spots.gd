class_name CoopSoySaveSpots
extends Node
## Authenticated, sequenced claims; each party character owns its own unlocks.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary[String, int] = {}
var _pending: Dictionary[String, int] = {}

func _ready() -> void:
	name = "SoySaveSpotSync"
	process_physics_priority = session.process_physics_priority + 1
	session.game.soy_spots.authoritative = session.authority
	session.game.soy_spots.request_claim = request
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_members_changed)

func request(index: int) -> void:
	_sequence += 1
	var data := {"type": "soy_spot_claim", "sequence": _sequence, "spot": index}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority or data.get("type") != "soy_spot_claim": return
	if not session.room.playing or session.opening.active() or not session.roster.party.has(key): return
	if not ExplorationProtocol.sequence(data.get("sequence")) or data.sequence <= _seen.get(key, -1): return
	if not ExplorationProtocol.sequence(data.get("spot")) or data.spot >= session.game.soy_spots.spots.size(): return
	_seen[key] = int(data.sequence)
	_pending[key] = int(data.spot)

func _physics_process(_delta: float) -> void:
	for key in _pending:
		if not session.room.playing or session.opening.active() or not session.roster.party.has(key): continue
		if session.duel.is_participant(key): continue
		var member: CoopActor = session.roster.party[key]
		if member.spectating or member.health.current <= 0.0: continue
		if session.game.soy_spots.perform(member.actor, member.soy_spots, _pending[key]) and member.hud != null:
			member.hud.announce("Soybean save spot claimed · %s" % SoySaveSpotSites.TITLES[_pending[key]])
	_pending.clear()

func _members_changed() -> void:
	for key in _seen.keys():
		if not session.roster.party.has(key):
			_seen.erase(key)
			_pending.erase(key)
