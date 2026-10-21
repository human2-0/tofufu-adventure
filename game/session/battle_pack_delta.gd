class_name BattlePackDelta
extends RefCounted
## Indexed value changes keep healing ticks from resending every bag and world drop.
const FIELDS: Array[String] = ["pack", "chests", "drops"]
const LIMITS: Array[int] = [BattleProtocol.CAPACITY, BattlePackWire.CHESTS, BattlePackWire.DROPS]

static func compact(packet: Dictionary, previous: Array, baseline: int, full: bool) -> Array:
	var current: Array = [packet.pack, packet.chests, packet.drops]
	if not full and not previous.is_empty():
		var changes: Array = []
		for field in 3:
			var changed: Array = []
			for i in current[field].size():
				if i < previous[field].size() and current[field][i] == previous[field][i]: continue
				var row: Array = current[field][i]
				if field == 0 and i < previous[0].size() and row.slice(0, 3) == previous[0][i].slice(0, 3): row = [row[0], row[3]]
				changed.append([i, row])
			changes.append(changed)
			packet.erase(FIELDS[field])
		packet.pack_delta = changes
		packet.pack_base = baseline
	return current.duplicate(true)

static func expand(packet: Dictionary, previous: Array) -> bool:
	var delta: Variant = packet.get("pack_delta")
	if not delta is Array or delta.size() != 3: return false
	for field in 3:
		if packet.has(FIELDS[field]) or not delta[field] is Array or delta[field].size() > LIMITS[field]: return false
		var values: Array = previous[field].duplicate()
		var seen: Dictionary = {}
		for change: Variant in delta[field]:
			if not change is Array or change.size() != 2 or not BattleProtocol.integer(change[0], 0, mini(values.size() - int(field == 0), LIMITS[field] - 1)): return false
			var index := int(change[0])
			if seen.has(index) or not change[1] is Array: return false
			seen[index] = true
			var row: Array = change[1]
			if field == 0 and row.size() == 2:
				if index >= values.size() or not BattleProtocol.integer(row[0], int(values[index][0]), int(values[index][0])): return false
				row = [row[0], values[index][1], values[index][2], row[1]]
			if index == values.size(): values.append(row)
			else: values[index] = row
		packet[FIELDS[field]] = values
	return true
