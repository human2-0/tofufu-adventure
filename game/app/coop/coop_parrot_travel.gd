class_name CoopParrotTravel
extends Node
## Reliable mount/landing intents; authority rechecks proximity and current actor state.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary[String, int] = {}
var _pending: Dictionary[String, String] = {}

func _ready() -> void:
	name = "CoopParrotTravel"
	process_physics_priority = session.process_physics_priority + 1
	session.game.parrot_travel.session = session
	session.game.parrot_travel.controls.request_action = request
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_members_changed)

func request(action: String) -> void:
	_sequence += 1
	var data := {"type": "parrot_action", "sequence": _sequence, "action": action}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority:
		if key == session.room.host_key and data.get("type") == "parrot_result" and data.get("accepted") is bool:
			if not data.accepted: session.game.hud.announce("Flight unavailable / Move closer to your parrot, or fly over clear, dry ground.")
		return
	if data.get("type") != "parrot_action" or not session.roster.party.has(key): return
	if not ExplorationProtocol.sequence(data.get("sequence")) or data.sequence <= _seen.get(key, -1): return
	if data.get("action") not in ["mount", "land"]: return
	_seen[key] = int(data.sequence)
	_pending[key] = str(data.action)

func _physics_process(_delta: float) -> void:
	for key: String in _pending:
		if not session.roster.party.has(key): continue
		var actor: Player = session.roster.party[key].actor
		var accepted: bool = session.game.parrot_travel.start(actor) if _pending[key] == "mount" else session.game.parrot_travel.request_land(actor)
		if key != session.room.local_key: session.room.send_game(key, {"type": "parrot_result", "accepted": accepted})
		elif not accepted: session.game.hud.announce("Flight unavailable / Move closer to your parrot, or fly over clear, dry ground.")
	_pending.clear()

func _members_changed() -> void:
	for key: String in _seen.keys():
		if not session.roster.party.has(key):
			_seen.erase(key)
			_pending.erase(key)
