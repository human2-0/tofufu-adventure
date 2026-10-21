class_name BattleReplication
extends RefCounted
## Twenty-Hz survivors and bounded PvE; loot only on change/keyframes.

var game: BattleRoyaleGame
var sequence: int = 0
var snapshot_sequence: int = 0
var last_packet: float = 0
var last_sequences: Dictionary = {}
var activity: Dictionary = {}
var input_clock: float = 0
var snapshot_clock: float = 0
var pending: Array = [0.0, 0.0, 0.0, 1.0, 0]
var loot_cache: Array = []
var combat_cache: Array = []
var combat_sequence: int = 0
var pack_cache: Array = []
var mob_cache: Array = []
var sent_snapshots: int = 0
var published_winner: int = -2

func workers() -> Array[String]:
	var result: Array[String] = []
	for slot in game.room.members.size():
		if game.match_state.rows[slot][17] == 0: result.append(str(game.room.members[slot].key))
	result.sort()
	return result

func owner_of(slot: int, available: Array[String]) -> String:
	return available[slot % available.size()] if not available.is_empty() else game.room.host_key

func step(delta: float, command: PlayerCommand) -> void:
	var encoded := BattleInputBuffer.encode(command, game.bodies[game.local_slot].position)
	encoded[4] = int(encoded[4]) | (int(pending[4]) & BattleInputBuffer.EDGES)
	pending = encoded
	input_clock += delta
	snapshot_clock += delta
	if game.deployment.active():
		if game.room.authority() and snapshot_clock >= 0.05:
			snapshot_clock = fmod(snapshot_clock, 0.05)
			_publish()
		elif not game.room.authority() and game.elapsed - last_packet > 4: game.room.authority_lost()
		return
	if game.match_state.winner != -2:
		if game.room.authority() and (sent_snapshots == 0 or game.match_state.winner != published_winner or snapshot_clock >= 1):
			snapshot_clock = fmod(snapshot_clock, 1)
			_publish()
		elif not game.room.authority() and game.elapsed - last_packet > 4: game.room.authority_lost()
		return
	if input_clock >= 0.05:
		input_clock = fmod(input_clock, 0.05)
		sequence += 1
		var inputs: Array = [[game.local_slot, pending]]
		pending = pending.duplicate()
		pending[4] = int(pending[4]) & ~BattleInputBuffer.EDGES
		var available := workers()
		for slot in game.match_state.rows.size():
			if slot % 2 != sequence % 2: continue
			if game.match_state.rows[slot][17] == 1 and game.match_state.rows[slot][8] > 0 and owner_of(slot, available) == game.room.local_key:
				inputs.append([slot, BattleBot.command(slot, game.match_state)])
		var packet := {"kind": "br_input", "epoch": game.room.epoch, "term": game.room.term, "seq": sequence, "inputs": inputs}
		if game.room.authority(): receive(game.room.local_key, packet)
		else: game.room.send(game.room.host_key, packet)
	if game.room.authority():
		_fallback_bots()
		if snapshot_clock >= 0.05:
			snapshot_clock = fmod(snapshot_clock, 0.05)
			_publish()
	elif game.elapsed - last_packet > 4:
		game.room.authority_lost()

func receive(key: String, packet: Dictionary) -> void:
	if packet.get("epoch") != game.room.epoch or packet.get("term") != game.room.term or game.room.phase != "playing": return
	if packet.get("kind") in ["br_plant", "br_plant_result"]:
		game.deployment.receive(key, packet)
	elif packet.get("kind") == "br_state" and not game.room.authority():
		_state(key, packet)
	elif packet.get("kind") == "br_pack" and game.room.authority():
		game.pack.requests.receive(key, packet)
	elif packet.get("kind") == "br_pack_result" and key == game.room.host_key:
		var requests := game.pack.requests
		if BattleProtocol.integer(packet.get("seq"), 1, requests.sequence) and packet.get("ok") is bool:
			if requests.replies.size() >= 32: requests.replies.erase(requests.replies.keys()[0])
			requests.replies[int(packet.seq)] = packet.ok
	elif packet.get("kind") == "br_input" and game.room.authority():
		_input(key, packet)

func _input(key: String, packet: Dictionary) -> void:
	if not BattleProtocol.integer(packet.get("seq"), 1, 2147483647): return
	var previous := int(last_sequences.get(key, 0))
	if int(packet.seq) <= previous or int(packet.seq) > previous + 240: return
	var inputs: Variant = packet.get("inputs")
	if not inputs is Array or inputs.is_empty() or inputs.size() > game.match_state.rows.size(): return
	var available := workers()
	var seen: Dictionary = {}
	for value: Variant in inputs:
		if not value is Array or value.size() != 2 or not BattleProtocol.integer(value[0], 0, game.match_state.rows.size() - 1) or not BattleProtocol.command(value[1]): return
		var slot := int(value[0])
		if seen.has(slot): return
		seen[slot] = true
		if game.match_state.rows[slot][17] == 1:
			if owner_of(slot, available) != key: return
		elif slot >= game.room.members.size() or game.room.members[slot].key != key: return
	last_sequences[key] = int(packet.seq)
	activity[key] = game.elapsed
	for value: Array in inputs:
		game.simulation.buffer.accept(int(value[0]), value[1], game.simulation.clock)

func _fallback_bots() -> void:
	for slot in game.match_state.rows.size():
		if slot < game.room.members.size() and not game.room.connected.has(game.room.members[slot].key): game.match_state.rows[slot][17] = 1
		if game.match_state.rows[slot][8] <= 0: continue
		if game.match_state.rows[slot][17] != 1: continue
		if game.simulation.clock - float(game.simulation.buffer.received.get(slot, -10.0)) > BattleProtocol.INPUT_TTL:
			game.simulation.buffer.accept(slot, BattleBot.command(slot, game.match_state), game.simulation.clock)

func _publish() -> void:
	if game.pack != null: game.pack.capture()
	if game.room.offline: return
	game.combat.capture()
	game.mobs.capture()
	game.room.migration.heard = game.room.clock
	sent_snapshots += 1
	var include_loot := game.match_state.loot != loot_cache or sent_snapshots % 20 == 0
	var packet := game.match_state.capture(include_loot)
	BattleDeploymentWire.compact(packet, sent_snapshots == 1 or sent_snapshots % 20 == 0)
	if not combat_cache.is_empty() and sent_snapshots % 20 != 0:
		packet.combat_delta = BattleCombatWire.difference(combat_cache, packet.combat)
		packet.combat_base = combat_sequence
		packet.erase("combat")
	combat_cache = game.match_state.combat.duplicate(true)
	if packet.has("pack"):
		pack_cache = BattlePackDelta.compact(packet, pack_cache, combat_sequence, sent_snapshots % 20 == 0)
	mob_cache = BattleMobDelta.compact(packet, mob_cache, combat_sequence, sent_snapshots % 20 == 0)
	combat_sequence = int(packet.seq)
	packet.kind = "br_state"
	packet.epoch = game.room.epoch
	packet.term = game.room.term
	if include_loot: loot_cache = game.match_state.loot.duplicate(true)
	game.room.broadcast(BattleWire.packet(packet))
	# Offset recovery work from complete keyframes; reuse this tick's combat capture.
	if sent_snapshots == 1 or sent_snapshots % 20 == 10 or game.match_state.winner != published_winner: game.recovery.publish(false)
	published_winner = game.match_state.winner

func _state(key: String, packet: Dictionary) -> void:
	if key != game.room.host_key or packet.get("epoch") != game.room.epoch: return
	if not BattleProtocol.integer(packet.get("seq"), snapshot_sequence + 1, 2147483647): return
	var candidate := BattleWire.restore(packet)
	if candidate.is_empty(): return
	if not BattleDeploymentWire.expand(candidate, game.match_state.deployment): return
	if not candidate.has("loot"): candidate.loot = game.match_state.loot
	if candidate.has("mob_delta"):
		if not BattleProtocol.integer(candidate.get("mob_base"), snapshot_sequence, snapshot_sequence): return
		if not BattleMobDelta.expand(candidate, game.match_state.mobs): return
	if candidate.has("pack_delta"):
		if not BattleProtocol.integer(candidate.get("pack_base"), snapshot_sequence, snapshot_sequence): return
		if not BattlePackDelta.expand(candidate, [game.match_state.pack, game.match_state.chests, game.match_state.drops]): return
	if not candidate.has("pack") and not game.match_state.pack.is_empty():
		for field in ["pack", "chests", "drops"]: candidate[field] = game.match_state.get(field)
	if candidate.has("combat_delta"):
		if not BattleProtocol.integer(candidate.get("combat_base"), snapshot_sequence, snapshot_sequence): return
		candidate.combat = BattleCombatWire.apply(game.match_state.combat, candidate.combat_delta)
	if not candidate.has("combat") or not candidate.has("mobs") or not BattleProtocol.snapshot(candidate): return
	if not game.mobs.accepts(candidate.mobs): return
	if BattleOptions.canonical(candidate.options) != game.room.options or candidate.actors.size() != game.bodies.size(): return
	if float(candidate.time) < game.match_state.time: return
	snapshot_sequence = int(candidate.seq)
	last_packet = game.elapsed
	game.room.migration.heard = game.room.clock
	game.match_state.deployment = candidate.get("deployment", {}).duplicate(true)
	game.match_state.combat = candidate.get("combat", [])
	game.match_state.rows = candidate.actors
	game.match_state.mobs = candidate.mobs
	game.mobs.present()
	game.match_state.loot = candidate.loot
	game.match_state.time = float(candidate.time)
	game.match_state.circle = Vector2(candidate.circle[0], candidate.circle[1]) if candidate.has("circle") else BattleRing.CENTER
	game.match_state.stats = candidate.get("stats", BattleRoundStats.create(game.bodies.size())).duplicate(true)
	game.match_state.winner = int(candidate.winner)
	if candidate.has("pack"):
		game.match_state.pack = candidate.pack
		game.match_state.chests = candidate.chests
		game.match_state.drops = candidate.drops
		BattlePackSnapshot.apply(game.pack, candidate.pack)
	game.combat.present()
	game.match_state.alive = 0
	for row: Array in candidate.actors:
		if row[8] > 0: game.match_state.alive += 1
