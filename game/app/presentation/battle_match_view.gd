class_name BattleMatchView
extends RefCounted
## Formats the match loop; simulation owns all goals, damage and results.

var game: BattleRoyaleGame
var tactical: BattleRoundHUD
var results: BattleResultPanel
var career: BattleCareer
var ready: bool = false
var rematch_status: String = ""
var _shown: bool = false
var _observed: bool = false
var _damage: float = 0
var _taken: float = 0
var _kills: int = 0

func build() -> void:
	tactical = BattleRoundHUD.new()
	var damage_layer := CanvasLayer.new()
	damage_layer.layer = 18 # Above bag/loot panels; never inherits tactical visibility.
	game.hud.add_child(damage_layer)
	tactical.damage_flash = BattleDamageFlash.new()
	damage_layer.add_child(tactical.damage_flash)
	game.hud._root.add_child(tactical)
	results = BattleResultPanel.new()
	game.hud._root.add_child(results)
	tactical.results_requested.connect(results.show)
	results.replay_requested.connect(game.replay_requested.emit)
	results.leave_requested.connect(game.leave_requested.emit)

func update() -> void:
	_base_hud()
	if game.room.phase == "recovering":
		tactical.damage_flash.cancel()
		results.hide()
		tactical.hide()
		_shown = false
		_observed = false
		return
	var state := game.match_state
	var row: Array = state.rows[game.local_slot]
	var stats: Array = state.stats[game.local_slot]
	if _observed:
		tactical.feedback(stats[0] > _damage, stats[1] > _taken, row[12] > _kills)
	_damage = float(stats[0])
	_taken = float(stats[1])
	_kills = int(row[12])
	_observed = true
	tactical.visible = not game.deployment.active() and not game.hud.exit_panel.visible and not game.pack_ui.blocked()
	var progress := BattleRoundStats.goals(state, game.local_slot)
	tactical.display_objectives(progress)
	var complete: bool = state.winner != -2 or (row[8] <= 0 and row[13] > 0)
	tactical.results_button.visible = complete
	if not complete:
		_shown = false
		results.hide()
		return
	_recap()
	if not _shown and game.room.phase != "recovering":
		_shown = true
		results.show()

func _rotation() -> Dictionary:
	var state := game.match_state
	var radar := game.hud.radar
	radar.next_center = BattleRing.next_center(state.time, state.circle)
	radar.next_radius = BattleRing.RADII[BattleRing.stage(state.time) + 1]
	var actor := game.bodies[game.watch_slot]
	var at := Vector2(actor.position.x, actor.position.z)
	var offset := at - radar.next_center
	var edge := maxf(0, radar.next_radius - 5)
	radar.destination = at if offset.length() <= edge else radar.next_center + offset.normalized() * edge
	var distance := ceili(at.distance_to(radar.destination))
	var seconds := ceili(BattleRing.phase_remaining(state.time))
	var right := Vector2(game.camera.global_basis.x.x, game.camera.global_basis.x.z).normalized()
	var forward := Vector2(-game.camera.global_basis.z.x, -game.camera.global_basis.z.z).normalized()
	var direction := (radar.destination - at).normalized()
	return {"closing": BattleRing.closing(state.time), "phase_seconds": seconds, "zone_distance": distance,
		"unsafe": BattleRing.outside(actor.position, state.time, state.circle), "zone_heading": atan2(direction.dot(right), direction.dot(forward)), "view_heading": forward}

func _recap() -> void:
	var state := game.match_state
	var summary := BattleRoundStats.summary(state, game.local_slot)
	results.heading.text = tr("TOFUFU ROYALE! Victory") if summary.won else tr("Your round · Placed #%d") % summary.rank
	results.details.text = tr("KOs: %d · Damage: %d · Chests: %d\nSurvived: %ds · Goals completed: %d/3") % [summary.kills, summary.damage, summary.chests, summary.seconds, summary.goals]
	if not state.mobs.is_empty(): results.details.text += "\n" + tr("Hunts completed: %d") % state.mobs[1][game.local_slot]
	results.progress.text = tr("Match XP +%d · Cosmetic career progress only") % summary.xp
	if career != null: results.progress.text += "\n" + tr("After this round: %s") % career.caption(summary.xp)
	results.replay.disabled = game.room.phase != "playing" or (not game.room.offline and state.winner == -2)
	results.replay.text = tr("Play again") if game.room.offline else (tr("Cancel ready") if ready else tr("Ready for rematch"))
	results.status.text = rematch_status
	if state.winner == -2 and not game.room.offline: results.status.text = tr("The round is still running. Spectate, or leave with your earned progress.")

func _base_hud() -> void:
	var row: Array = game.match_state.rows[game.local_slot]
	game.hud.show_recovery(tr(game.room.status) if game.room.phase == "recovering" else "")
	var message := BattleResultText.message(game)
	game.hud.radar.teammates = []
	for slot in game.bodies.size():
		if slot != game.watch_slot and game.match_state.rows[slot][8] > 0 and BattleTeams.allies(game.room.options, game.watch_slot, slot):
			game.hud.radar.teammates.append(Vector2(game.bodies[slot].position.x, game.bodies[slot].position.z))
	game.hud.radar.chests = []
	for chest: Array in game.match_state.chests:
		if chest[4] == 0: game.hud.radar.chests.append(Vector2(chest[1], chest[3]))
	var data := {"alive": game.match_state.alive, "total": game.bodies.size(), "kills": row[12], "stage": BattleRing.stage(game.match_state.time) + 1,
		"hp": ceili(row[8]), "armour": ceili(row[9]),
		"reserve": row[18],
		"sp": ceili(game.combat.fighters[game.local_slot].combat.vitals.current), "tank": ceili(game.combat.fighters[game.local_slot].combat.sotjet.milk) if row[10] == 7 else -1,
		"deploying": game.deployment.active(), "result": message, "feed": game.presentation.feed_text(), "at": Vector2(game.bodies[game.watch_slot].position.x, game.bodies[game.watch_slot].position.z),
		"center": BattleRing.center(game.match_state.time, game.match_state.circle), "radius": BattleRing.radius(game.match_state.time)}
	data.merge(_rotation(), true)
	data.merge(BattleHUDValues.loadout(game), true)
	game.hud.display(data)

