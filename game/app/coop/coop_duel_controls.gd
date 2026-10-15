class_name CoopDuelControls
extends Node
## Authenticated, sequenced arena choices and surrender applied on physics ticks.

var duel: CoopDuel
var _sequence: int = 0
var _seen: Dictionary = {}
var _pending: Dictionary = {}

func _ready() -> void:
	duel.session.game.hud.arena.action_requested.connect(request)
	duel.session.room.gameplay_packet.connect(_packet)
	duel.session.roster.changed.connect(_members_changed)

func request(action: String, ranged: String, melee: String) -> void:
	_sequence += 1
	var state := duel.capture() if duel.session.authority else duel._view
	var data := {"type": "duel_action", "action": action, "ranged": ranged, "melee": melee,
		"sequence": _sequence, "match": state.get("match", 0)}
	if duel.session.authority: _packet(duel.session.room.local_key, data)
	else: duel.session.room.send_game(duel.session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not duel.session.authority or data.get("type") != "duel_action": return
	if not duel.session.roster.party.has(key) or not DuelProtocol.valid_action(data): return
	if data.match != duel.match_id or not duel.is_participant(key): return
	var last: int = int(_seen.get(key, 0))
	if data.sequence <= last or data.sequence > last + 240: return
	_seen[key] = int(data.sequence)
	_pending[key] = data.duplicate()

func _physics_process(_delta: float) -> void:
	if not duel.session.room.playing:
		_pending.clear()
		return
	for key: String in _pending:
		var data: Dictionary = _pending[key]
		if data.match != duel.match_id or not duel.is_participant(key): continue
		if data.action == "leave":
			if duel.phase in ["loadout", "entry"]: duel._abort("DUEL CANCELLED / A fighter declined.")
			else:
				var victor: String = duel.participants[1 - duel.participants.find(key)]
				duel._finish(victor)
				duel._announce("%s SURRENDERED / %s WINS" % [duel._name(key), duel._name(victor)])
		elif duel.phase == "loadout":
			if duel.agreement.accept(duel.participants.find(key), data.ranged, data.melee):
				duel.phase = "entry"
				duel.countdown = duel.COUNTDOWN_SECONDS
				duel._announce("LOADOUT AGREED / STARTS IN 5")
	_pending.clear()

func _members_changed() -> void:
	for key: String in _seen.keys():
		if key not in duel.session.room.members:
			_seen.erase(key)
			_pending.erase(key)
