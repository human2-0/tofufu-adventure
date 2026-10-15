class_name CoopDuelView
extends RefCounted
## Snapshot and local HUD formatting for duel state.

static func capture(duel: CoopDuel) -> Dictionary:
	return {"phase": duel.phase, "participants": duel.participants.duplicate(), "scores": duel.scores.duplicate(),
		"countdown": duel.countdown, "round": duel.round_number, "winner": duel.winner,
		"notice_seq": duel.notice_seq, "notice": duel.notice, "match": duel.match_id,
		"choices": duel.agreement.choices.duplicate(true) if duel.participants.size() == 2 else [], "setup_seconds": duel.agreement.remaining}

static func present(duel: CoopDuel, data: Variant) -> void:
	if not data is Dictionary or data.is_empty() or data == duel._view: return
	var active_phases: Array[String] = ["loadout", "entry", "fight", "round"]
	var entering: bool = data.get("phase", "idle") in active_phases and duel._view.get("phase", "idle") not in active_phases
	var stopping: bool = duel._view.get("phase") == "fight" and data.get("phase") in ["round", "complete", "idle"]
	duel._view = data.duplicate(true)
	if entering or stopping: duel._fighters.clear_party_projectiles()
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
	if state.phase == "loadout": phase_text = "CHOOSE LOADOUT"
	if state.phase == "entry": phase_text = "STARTS %d" % ceili(state.countdown)
	if state.phase == "complete": phase_text = "WINNER: %s" % duel.session.room.names.get(state.get("winner", ""), "Fufu")
	return "DUEL · %s %d - %d %s · %s" % [names[0], int(score[0]), int(score[1]), names[1], phase_text]

static func announce(duel: CoopDuel, text: String) -> void:
	duel.notice = text.left(100)
	duel.notice_seq += 1
	duel.session.game.hud.announce(duel.notice)

static func name_for(duel: CoopDuel, key: String) -> String:
	return str(duel.session.room.names.get(key, "Fufu"))

static func process(duel: CoopDuel) -> void:
	var state := capture(duel) if duel.session.authority else duel._view
	var active: bool = state.get("phase", "idle") in ["loadout", "entry", "fight", "round"]
	var keys: Array = state.get("participants", [])
	var local: String = duel.session.room.local_key
	var playing: bool = active and local in keys
	for key: String in duel.session.roster.actors:
		var label := duel.session.roster.actors[key].get_node_or_null("PartyName") as Label3D
		if label != null: label.visible = not playing or key == local
	duel.session.game.map.hidden_party.clear()
	if playing:
		for key: String in duel.session.roster.actors:
			if key != local: duel.session.game.map.hidden_party.append(key)
	var data := state.duplicate(true)
	data.participant = local in keys
	if keys.size() == 2:
		data.names = [("YOU · " if keys[0] == local else "") + name_for(duel, keys[0]), ("YOU · " if keys[1] == local else "") + name_for(duel, keys[1])]
		data.winner_index = keys.find(state.get("winner", ""))
		data.status = "ROUND %d · FIRST TO 10 · 2× PROJECTILE SPEED" % state.get("round", 1)
		if state.phase == "entry": data.status = "STARTS IN %d · FIRST TO 10" % ceili(state.countdown)
		if state.phase == "round": data.status = "NEXT ROUND IN %d · FIRST TO 10" % ceili(state.countdown)
		if state.phase == "complete": data.status = state.get("notice", "MATCH COMPLETE")
		if state.phase == "loadout":
			data.status = "AGREE ON YOUR LOADOUT · %ds" % ceili(state.get("setup_seconds", 60))
			var choices: Array = state.get("choices", [])
			if choices.size() == 2:
				if local in keys: data.choice = choices[keys.find(local)]
				var ready: Array[String] = []
				for index in 2:
					ready.append("%s: %s · %s" % [name_for(duel, keys[index]), "READY" if choices[index].ready else "CHOOSING", "Soygun" if choices[index].ranged == "soy_gun" else "Soyjet"])
				data.readiness = "\n".join(ready)
				if choices[0].ready and choices[1].ready and choices[0].ranged != choices[1].ranged: data.readiness += "\nDifferent ranged choices. Agree and accept again."
	var hud: HUD = duel.session.game.hud
	hud._notice.visible = state.get("phase") != "loadout" and not duel.session.game.inventory_window.visible
	hud._notice.offset_top = 172 if active or state.get("phase") == "complete" else 118
	hud._notice.offset_bottom = hud._notice.offset_top + 28
	hud.arena.present(data)
