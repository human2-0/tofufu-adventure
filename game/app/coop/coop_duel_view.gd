class_name CoopDuelView
extends RefCounted
## Snapshot and local HUD formatting for duel state.

static func capture(duel: CoopDuel) -> Dictionary:
	return {"phase": duel.phase, "participants": duel.participants.duplicate(), "scores": duel.scores.duplicate(),
		"countdown": duel.countdown, "round": duel.round_number, "winner": duel.winner,
		"notice_seq": duel.notice_seq, "notice": duel.notice}

static func present(duel: CoopDuel, data: Variant) -> void:
	if not data is Dictionary or data.is_empty(): return
	var active_phases: Array[String] = ["entry", "fight", "round"]
	var entering: bool = data.get("phase", "idle") in active_phases and duel._view.get("phase", "idle") not in active_phases
	duel._view = data.duplicate(true)
	if entering: duel._fighters.clear_party_projectiles()
	var sequence := int(data.get("notice_seq", 0))
	if sequence > duel._presented_notice:
		duel._presented_notice = sequence
		if not str(data.get("notice", "")).is_empty(): duel.session.game.hud.announce(data.notice)

static func status(duel: CoopDuel, local_key: String) -> String:
	var state := capture(duel) if duel.session.authority else duel._view
	if state.is_empty() or state.get("phase", "idle") == "idle": return ""
	var keys: Array = state.get("participants", [])
	if keys.size() != 2: return "DUEL · %s" % state.get("notice", "")
	var names := [str(duel.session.room.names.get(keys[0], "Fufu")), str(duel.session.room.names.get(keys[1], "Fufu"))]
	if keys[0] == local_key: names[0] = "YOU"
	if keys[1] == local_key: names[1] = "YOU"
	var score: Array = state.get("scores", [0, 0])
	var phase_text := "FIGHT" if state.phase == "fight" else "NEXT ROUND %d" % ceili(state.countdown)
	if state.phase == "entry": phase_text = "STARTS %d" % ceili(state.countdown)
	if state.phase == "complete": phase_text = "WINNER: %s" % duel.session.room.names.get(state.get("winner", ""), "Fufu")
	return "DUEL · %s %d - %d %s · %s" % [names[0], int(score[0]), int(score[1]), names[1], phase_text]

static func announce(duel: CoopDuel, text: String) -> void:
	duel.notice = text.left(100)
	duel.notice_seq += 1
	duel.session.game.hud.announce(duel.notice)

static func name_for(duel: CoopDuel, key: String) -> String:
	return str(duel.session.room.names.get(key, "Fufu"))
