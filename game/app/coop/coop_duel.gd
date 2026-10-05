class_name CoopDuel
extends Node
## Host-owned two-player arena loop and replica-friendly match presentation.

signal entry_started(participants: Array[String])

const SCORE_TO_WIN: int = 10
const COUNTDOWN_SECONDS: float = 5.0
const COMPLETE_HOLD_SECONDS: float = 2.0
var session: CoopSession
var phase: String = "idle"
var participants: Array[String] = []
var scores: Array[int] = []
var countdown: float = 0.0
var round_number: int = 0
var winner: String = ""
var notice: String = ""
var notice_seq: int = 0
var _view: Dictionary = {}
var _presented_notice: int = -1
var _waiting_for_departure: bool = false
var _complete_remaining: float = 0.0
var _pads := CoopDuelPads.new()
var _fighters := CoopDuelFighters.new()

func _ready() -> void:
	_pads.session = session
	_fighters.session = session

func step(delta: float) -> void:
	if not session.authority or session.opening.active(): return
	if phase in ["fight", "round"]: _fighters.contain(participants)
	if phase == "idle":
		if _waiting_for_departure:
			if not _pads.contains_pair(participants): _reset_match()
			return
		var pair := _pads.pair()
		if pair.size() == 2: _begin_entry(pair)
	elif phase == "entry" and not _pads.contains_pair(participants):
		_cancel_entry()
	elif phase in ["entry", "round"]:
		_tick_countdown(delta)
	elif phase == "complete":
		_complete_remaining = maxf(0.0, _complete_remaining - delta)
		if _complete_remaining == 0.0 and not _pads.contains_pair(participants): _reset_match()

func capture() -> Dictionary:
	return CoopDuelView.capture(self)

func present(data: Variant) -> void:
	CoopDuelView.present(self, data)

func status(local_key: String) -> String:
	return CoopDuelView.status(self, local_key)

func is_participant(key: String) -> bool:
	return phase in ["entry", "fight", "round"] and key in participants

func members_changed() -> void:
	if phase not in ["entry", "fight", "round"]: return
	for key in participants:
		if not session.roster.party.has(key):
			_abort("DUEL CANCELLED / A player left the meadow.")
			return
	_fighters.filter_targets(participants)

func checkpoint_party(current: Dictionary) -> Dictionary:
	return _fighters.checkpoint_party(current)

func session_ended() -> void:
	if phase in ["entry", "fight", "round"]:
		_abort("DUEL CANCELLED / The co-op session ended.")

func _begin_entry(pair: Array[String]) -> void:
	if not session.authority or phase != "idle" or pair.size() != 2 or pair[0] == pair[1]: return
	if not session.roster.party.has(pair[0]) or not session.roster.party.has(pair[1]): return
	participants = pair
	scores = [0, 0]
	_fighters.clear_party_projectiles()
	_fighters.save_entry(participants, Callable(self, "_defeated"))
	_fighters.filter_targets(participants)
	entry_started.emit(participants.duplicate())
	phase = "entry"
	countdown = COUNTDOWN_SECONDS
	round_number = 0
	winner = ""
	_announce("DUEL / %s VS %s / 5" % [_name(pair[0]), _name(pair[1])])

func _tick_countdown(delta: float) -> void:
	var before := ceili(countdown)
	countdown = maxf(0.0, countdown - delta)
	var after := ceili(countdown)
	if after < before and after > 0: _announce(str(after))
	if countdown > 0.0: return
	_start_round(phase == "entry")

func _start_round(first: bool) -> void:
	phase = "fight"
	countdown = 0.0
	round_number = 1 if first else round_number + 1
	_fighters.start_round(participants, session.game.world.duel_arena.spawn_positions())
	_announce("FIGHT! ROUND %d" % round_number)

func _defeated(_loser: CoopActor, key: String) -> void:
	if not session.authority or phase == "entry":
		_cancel_entry()
		return
	if phase != "fight" or participants.find(key) < 0: return
	var winner_index := 1 - participants.find(key)
	scores[winner_index] += 1
	_fighters.clear_projectiles(participants)
	var score_text := "%d - %d" % [scores[0], scores[1]]
	if scores[winner_index] >= SCORE_TO_WIN:
		_finish(participants[winner_index])
		return
	phase = "round"
	countdown = COUNTDOWN_SECONDS
	for participant in participants:
		session.roster.party[participant].health.invulnerability = COUNTDOWN_SECONDS + 1.0
	_announce("%s SCORES / %s / 5" % [_name(participants[winner_index]), score_text])

func _finish(winner_key: String) -> void:
	_fighters.finish(participants)
	winner = winner_key
	phase = "complete"
	countdown = 0.0
	_complete_remaining = COMPLETE_HOLD_SECONDS
	_waiting_for_departure = true
	_announce("%s WINS THE DUEL! FIRST TO 10." % _name(winner_key))

func _cancel_entry() -> void:
	_fighters.cancel_entry(participants)
	participants.clear()
	scores.clear()
	phase = "idle"
	countdown = 0.0
	_complete_remaining = 0.0
	winner = ""
	_waiting_for_departure = false
	_announce("DUEL CANCELLED / Both players must stay on their tiles.")

func _abort(message: String) -> void:
	_fighters.abort(participants)
	participants.clear()
	scores.clear()
	phase = "idle"
	countdown = 0.0
	_complete_remaining = 0.0
	winner = ""
	round_number = 0
	_waiting_for_departure = false
	_announce(message)

func _reset_match() -> void:
	participants.clear()
	scores.clear()
	winner = ""
	round_number = 0
	phase = "idle"
	_complete_remaining = 0.0
	_waiting_for_departure = false

func _announce(text: String) -> void:
	CoopDuelView.announce(self, text)

func _name(key: String) -> String:
	return CoopDuelView.name_for(self, key)
