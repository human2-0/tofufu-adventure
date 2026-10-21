class_name BattleResultText
extends RefCounted
## Translated match/team outcome and partner status; identities stay opaque.

static func message(game: BattleRoyaleGame) -> String:
	var state := game.match_state
	var row: Array = state.rows[game.local_slot]
	var text := ""
	if not game.playing: text = game.tr("Preparing the map · Waiting for peers")
	elif game.deployment.active(): text = game.tr("Your soybean plant is opening · Get ready!")
	elif state.time < BattleRing.GRACE: text = game.tr("Deploying · %ds · Loot unlocks when the match begins") % ceili(BattleRing.GRACE - state.time)
	elif state.winner != -2:
		if state.winner < 0: text = game.tr("The storm claimed every bean · Draw")
		elif BattleOptions.duos(state.options):
			var first := BattleTeams.team(state.options, state.winner) * 2
			text = game.tr("Tofufu Royale! %s and %s win") % [game.name_of(first), game.name_of(first + 1)]
		else: text = game.tr("Tofufu Royale! %s wins") % game.name_of(state.winner)
	elif row[8] <= 0:
		text = game.tr("Placed #%d · Spectating %s · N for next survivor") % [row[13], game.name_of(game.watch_slot)] if row[13] > 0 else game.tr("Your duo is still in the match · Spectating %s") % game.name_of(game.watch_slot)
	elif BattleRing.outside(game.bodies[game.local_slot].position, state.time, state.circle): text = game.tr("Storm damage! Follow the radar line to safety")
	return text

static func partner(game: BattleRoyaleGame) -> String:
	var state := game.match_state
	if not BattleOptions.duos(state.options): return ""
	var buddy := game.local_slot ^ 1
	if buddy >= state.rows.size(): return ""
	return game.tr("Duo partner: %s · %d HP · Teams left: %d") % [game.name_of(buddy), ceili(state.rows[buddy][8]), BattleTeams.survivors(state).size()]
