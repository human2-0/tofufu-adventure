class_name BattleGunfirePings
extends RefCounted
## Cosmetic last-shot positions; existing confirmed combat events supply every ping.

const RANGE: float = 100.0
const DURATION: float = 2.0
var game: BattleRoyaleGame
var _seen: Dictionary[int, Vector4i] = {}
var _hunt_seen: Dictionary[int, int] = {}
var _pings: Dictionary[int, Vector3] = {}
var _viewer: int = -1
var _replica_ready: bool = false

func reset() -> void:
	_seen.clear()
	_hunt_seen.clear()
	if not game.match_state.mobs.is_empty():
		for id in game.match_state.mobs[0].size(): _hunt_seen[id] = int(game.match_state.mobs[0][id][14][12])
	_pings.clear()
	_viewer = game.watch_slot
	for slot in game.combat.fighters.size():
		if game.room.authority():
			_seen[slot] = _live_sequence(game.combat.fighters[slot].combat)
		elif slot < game.match_state.combat.size():
			_seen[slot] = _wire_sequence(BattleCombatWire.unpack(game.match_state.combat[slot]))
	_publish()

func update(delta: float) -> void:
	if _viewer != game.watch_slot: reset()
	for slot: int in _pings.keys():
		_pings[slot].z -= delta
		if _pings[slot].z <= 0: _pings.erase(slot)
	if game.room.authority():
		for slot in game.combat.fighters.size():
			var combat := game.combat.fighters[slot].combat
			var sequence := _live_sequence(combat)
			if _seen.get(slot, Vector4i(-1, -1, -1, -1)) == sequence: continue
			_observe(slot, sequence, [combat.gun.shot_origin, combat.gun.ricochet_origin, combat.sotjet.origin, combat.bow.origin])
	_publish()

func replica(slot: int, state: Dictionary) -> void:
	if _viewer != game.watch_slot: reset()
	if not _replica_ready:
		# The first accepted snapshot may contain shots fired while this peer loaded.
		reset()
		_replica_ready = true
	var sequence := _wire_sequence(state)
	if _seen.get(slot, sequence) == sequence: return
	_observe(slot, sequence, [CombatState._vector(state.shot_origin),
		CombatState._vector(state.ricochet_origin), CombatState._vector(state.jet_origin), CombatState._vector(state.bow_origin)])

func _observe(slot: int, sequence: Vector4i, origins: Array[Vector3]) -> void:
	var previous: Vector4i = _seen.get(slot, sequence)
	_seen[slot] = sequence
	if not game.playing or game.deployment.active() or game.match_state.winner != -2: return
	if BattleTeams.allies(game.match_state.options, _viewer, slot): return
	var listener := game.bodies[_viewer].global_position
	for kind in 4:
		if sequence[kind] <= previous[kind] or listener.distance_squared_to(origins[kind]) > RANGE * RANGE: continue
		_pings[slot] = Vector3(origins[kind].x, origins[kind].z, DURATION)

func _publish() -> void:
	var radar := game.hud.radar
	if _pings.is_empty() and radar.gunfire.is_empty(): return
	radar.gunfire.clear()
	for ping: Vector3 in _pings.values():
		radar.gunfire.append(Vector3(ping.x, ping.y, clampf(ping.z / DURATION, 0, 1)))
	radar.queue_redraw()

func _live_sequence(combat: PlayerCombat) -> Vector4i:
	return Vector4i(combat.gun.shot_sequence, combat.gun.ricochet_sequence, combat.sotjet.sequence, combat.bow.sequence)

func _wire_sequence(state: Dictionary) -> Vector4i:
	return Vector4i(int(state.shot), int(state.ricochet), int(state.jet_sequence), int(state.bow_shot))

func hunt(id: int, sequence: int, at: Vector3) -> void:
	var previous: int = _hunt_seen.get(id, 0)
	_hunt_seen[id] = sequence
	if sequence <= previous or not game.playing or game.deployment.active() or game.match_state.winner != -2: return
	if game.bodies[game.watch_slot].global_position.distance_squared_to(at) > RANGE * RANGE: return
	_pings[-1 - id] = Vector3(at.x, at.z, DURATION)
