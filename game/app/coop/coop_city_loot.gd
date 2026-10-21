class_name CoopCityLoot
extends Node
## Authenticated bounded requests; guests only present the host's opened mask/drops.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary[String, int] = {}
var _pending: Dictionary[String, int] = {}

func _ready() -> void:
	process_physics_priority = session.process_physics_priority + 1
	session.game.city_loot.authoritative = session.authority
	session.game.city_loot.request_open = request
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_members_changed)

func request(index: int) -> void:
	_sequence += 1
	var data := {"type": "city_chest_open", "sequence": _sequence, "chest": index}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority or data.get("type") != "city_chest_open": return
	if not session.room.playing or session.opening.active() or not session.roster.party.has(key): return
	if not ExplorationProtocol.sequence(data.get("sequence")) or data.sequence <= _seen.get(key, -1): return
	if not ExplorationProtocol.sequence(data.get("chest")) or data.chest >= CityLootSites.POINTS.size(): return
	_seen[key] = int(data.sequence)
	_pending[key] = int(data.chest)

func _physics_process(_delta: float) -> void:
	for key in _pending:
		if not session.room.playing or session.opening.active() or not session.roster.party.has(key) or session.duel.is_participant(key): continue
		var member: CoopActor = session.roster.party[key]
		if member.spectating or member.health.current <= 0 or member.actor.transport_active: continue
		session.game.city_loot.perform(member.actor, _pending[key])
	_pending.clear()

func _members_changed() -> void:
	for key in _seen.keys():
		if session.roster.party.has(key): continue
		_seen.erase(key)
		_pending.erase(key)
