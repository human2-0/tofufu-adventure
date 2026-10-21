class_name BattleTeams
extends RefCounted
## Stable pairs follow lobby order; remaining CPUs complete the roster.

static func team(options: Array, slot: int) -> int:
	return floori(slot / 2.0) if BattleOptions.duos(options) else slot

static func allies(options: Array, first: int, second: int) -> bool:
	return first >= 0 and second >= 0 and team(options, first) == team(options, second)

static func survivors(state: BattleMatch) -> Array[int]:
	var result: Array[int] = []
	for slot in state.rows.size():
		var id := team(state.options, slot)
		if state.rows[slot][8] > 0 and not result.has(id): result.append(id)
	return result

static func finish(state: BattleMatch) -> void:
	var remaining := survivors(state)
	if remaining.size() > 1: return
	state.winner = -1
	if remaining.is_empty(): return
	for slot in state.rows.size():
		if team(state.options, slot) != remaining[0]: continue
		state.rows[slot][13] = 1
		if state.winner == -1 and state.rows[slot][8] > 0: state.winner = slot

static func eliminated(state: BattleMatch, slot: int) -> void:
	if not BattleOptions.duos(state.options):
		state.rows[slot][13] = state.alive + 1
		return
	var id := team(state.options, slot)
	var remaining := survivors(state)
	if remaining.has(id): return
	for other in state.rows.size():
		if team(state.options, other) == id: state.rows[other][13] = remaining.size() + 1
