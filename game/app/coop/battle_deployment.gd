class_name BattleDeployment
extends RefCounted
## Equal-delay authenticated plant intents and the frozen pre-match clock.
var game: BattleRoyaleGame
var panel: BattleDeploymentPanel
var sequence: int = 0
var seen: Dictionary = {}
var queue: Array = []
var turn: int = 0

func build() -> void:
	panel = BattleDeploymentPanel.new()
	game.add_child(panel)
	panel.chosen.connect(request)
	panel.leave_requested.connect(game.leave_requested.emit)
	var view := BattlePlantView.new()
	view.game = game
	game.add_child(view)

func active() -> bool:
	if game == null: return false
	return BattleDeploymentState.active(game.match_state.deployment) or (not game.room.authority() and game.match_state.deployment.is_empty() and game.match_state.time == 0)

func request(plant: int, confirm: bool) -> void:
	sequence += 1
	var packet := {"kind": "br_plant", "epoch": game.room.epoch, "term": game.room.term, "seq": sequence, "plant": plant, "confirm": confirm}
	if game.room.authority(): receive(game.room.local_key, packet)
	else: game.room.send(game.room.host_key, packet)

func receive(key: String, packet: Dictionary) -> void:
	if packet.get("epoch") != game.room.epoch or packet.get("term") != game.room.term: return
	if packet.get("kind") == "br_plant_result":
		if key == game.room.host_key and packet.get("ok") is bool and BattleProtocol.integer(packet.get("seq"), 1, sequence):
			panel.note("" if packet.ok else "This plant is taken or already confirmed. Choose another available plant.")
		return
	if not game.room.authority() or not active() or game.room.phase != "playing": return
	if int(game.match_state.deployment.get("stage", -1)) != 0: return
	if not BattleProtocol.integer(packet.get("seq"), int(seen.get(key, 0)) + 1, int(seen.get(key, 0)) + 240): return
	if not BattleProtocol.integer(packet.get("plant"), 0, BattleDeploymentState.LIMIT - 1) or not packet.get("confirm") is bool: return
	var slot := -1
	for i in game.room.members.size():
		if game.room.members[i].key == key: slot = i
	if slot < 0 or game.match_state.rows[slot][17] != 0 or queue.size() >= 80: return
	var pending := 0
	for entry: Array in queue:
		if entry[1] == slot: pending += 1
	if pending >= 4: return
	seen[key] = int(packet.seq)
	queue.append([game.elapsed + BattleProtocol.INPUT_DELAY, slot, packet.duplicate()])

func step(delta: float) -> void:
	if not game.room.authority() or not active(): return
	var state := game.match_state.deployment
	if state.is_empty(): return
	state.remaining = maxf(0, float(state.remaining) - delta)
	if int(state.stage) == 0:
		_flush()
		var ready := true
		for slot in game.room.members.size():
			if not game.room.connected.has(game.room.members[slot].key): game.match_state.rows[slot][17] = 1
			if game.match_state.rows[slot][17] == 0 and int(state.locked[slot]) == 0: ready = false
		if not ready and state.remaining > 0: return
		BattleDeploymentState.complete(state, game.room.options)
		queue.clear()
		if not BattlePlantLayout.emerge(game):
			game.room.finish("Could not safely deploy at this plant. Please start a new match.")
	elif int(state.stage) == 1 and state.remaining <= 0:
		state.stage = 2
		game.match_state.time = BattleRing.GRACE
		game.simulation.clock = BattleRing.GRACE
		game.simulation.buffer = BattleInputBuffer.new()
		game.pack.requests.clear()
		game.replication.pending = [0.0, 0.0, 0.0, 1.0, 256]

func _flush() -> void:
	turn += 1
	for offset in game.bodies.size():
		var slot := (turn + offset) % game.bodies.size()
		for entry: Array in queue.duplicate():
			if int(entry[1]) != slot or float(entry[0]) > game.elapsed: continue
			queue.erase(entry)
			var packet: Dictionary = entry[2]
			var ok := BattleDeploymentState.choose(game.match_state.deployment, game.room.options, slot, int(packet.plant), packet.confirm)
			var result := {"kind": "br_plant_result", "epoch": game.room.epoch, "term": game.room.term, "seq": packet.seq, "ok": ok}
			if slot == game.local_slot: receive(game.room.local_key, result)
			else: game.room.send(str(game.room.members[slot].key), result)

func update() -> void:
	if panel == null: return
	var state := game.match_state.deployment
	var choosing := active() and not state.is_empty() and int(state.stage) == 0 and game.room.phase == "playing" and not game.hud.exit_panel.visible
	if not choosing:
		panel.hide()
		return
	var states: Array[int] = []
	for plant in state.sites.size():
		var status := 0
		for slot in state.choices.size():
			if int(state.choices[slot]) != plant: continue
			status = 2 if slot == game.local_slot else (3 if BattleTeams.allies(game.room.options, slot, game.local_slot) else 1)
			if status == 2: break
		states.append(status)
	panel.display({"visible": true, "terrain": game.hud.radar.terrain_map, "sites": state.sites, "states": states,
		"choice": int(state.choices[game.local_slot]), "locked": state.locked[game.local_slot] == 1,
		"duos": BattleOptions.duos(game.room.options), "seconds": ceili(float(state.remaining))})

func clear_pending() -> void:
	queue.clear()
	seen.clear()
	sequence = 0
	if panel != null: panel.note("")
