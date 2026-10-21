class_name BattleMobDelta
extends RefCounted
## Ordered presentation deltas omit static homes and sleeping enemies between keyframes.

static func compact(packet: Dictionary, previous: Array, base: int, keyframe: bool) -> Array:
	var current: Array = packet.mobs
	if previous.is_empty() or current.is_empty() or keyframe: return current.duplicate(true)
	var changed: Array = []
	for id in current[0].size():
		if current[0][id] != previous[0][id]: changed.append([id, current[0][id].slice(4)])
	packet.mob_delta = [changed, current[1].duplicate() if current[1] != previous[1] else []]
	packet.mob_base = base
	packet.erase("mobs")
	return current.duplicate(true)

static func expand(packet: Dictionary, previous: Array) -> bool:
	var delta: Variant = packet.get("mob_delta")
	if previous.is_empty() or not delta is Array or delta.size() != 2: return false
	if not delta[0] is Array or delta[0].size() > previous[0].size() or not delta[1] is Array: return false
	var result := previous.duplicate(true)
	var seen: Dictionary = {}
	for pair: Variant in delta[0]:
		if not pair is Array or pair.size() != 2 or not BattleProtocol.integer(pair[0], 0, result[0].size() - 1): return false
		var id := int(pair[0])
		if seen.has(id) or not pair[1] is Array or pair[1].size() != BattleMobWire.ROW_SIZE - 4: return false
		seen[id] = true
		result[0][id] = result[0][id].slice(0, 4) + pair[1]
	if not delta[1].is_empty(): result[1] = delta[1].duplicate()
	if not BattleMobWire.valid(result, previous[1].size()): return false
	packet.mobs = result
	packet.erase("mob_delta")
	packet.erase("mob_base")
	return true
