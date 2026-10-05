class_name CoopAppleHarvest
extends Node
## Bounded E-to-shake intents; the authority alone creates shared fallen fruit.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary[String, int] = {}
var _pending: Dictionary[String, int] = {}

func _ready() -> void:
	name = "AppleHarvestSync"
	process_physics_priority = session.process_physics_priority + 1
	session.game.apple_harvest.authoritative = session.authority
	session.game.apple_harvest.request_harvest = request
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_members_changed)

func request(index: int) -> void:
	_sequence += 1
	var data := {"type": "apple_harvest", "sequence": _sequence, "tree": index}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority or data.get("type") != "apple_harvest": return
	if not session.room.playing or session.opening.active() or not session.roster.party.has(key): return
	if session.duel.is_participant(key): return
	if not ExplorationProtocol.sequence(data.get("sequence")) or data.sequence <= _seen.get(key, -1): return
	if not ExplorationProtocol.sequence(data.get("tree")) or data.tree >= session.game.world.apple_trees.size(): return
	_seen[key] = int(data.sequence)
	_pending[key] = int(data.tree)

func _physics_process(_delta: float) -> void:
	for key in _pending:
		if not session.room.playing or session.opening.active() or not session.roster.party.has(key): continue
		if session.duel.is_participant(key): continue
		var member: CoopActor = session.roster.party[key]
		if member.spectating or member.health.current <= 0.0: continue
		session.game.apple_harvest.perform(member.actor, _pending[key])
	_pending.clear()

func _members_changed() -> void:
	for key in _seen.keys():
		if not session.roster.party.has(key):
			_seen.erase(key)
			_pending.erase(key)
