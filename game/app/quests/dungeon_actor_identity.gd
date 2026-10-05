class_name DungeonActorIdentity
extends RefCounted
## Authority allocates collision-free puzzle IDs and persists their stable peer keys.

static func get_id(dungeon: TofuDungeon, key: String) -> int:
	if key.is_empty(): return 0
	if key == "solo": return 1
	if dungeon.actor_ids.has(key): return int(dungeon.actor_ids[key])
	if not dungeon.enabled: return 0
	var candidate: int = key.substr(0, 7).hex_to_int() + 2
	while dungeon.actor_ids.values().has(candidate): candidate += 1
	if dungeon.actor_ids.size() >= 64: return 0
	dungeon.actor_ids[key] = candidate
	return candidate

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() > 64: return false
	var seen: Array[int] = []
	for key: Variant in value:
		if not ExplorationProtocol.key(key): return false
		var id: Variant = value[key]
		if not TofuPuzzleContract.bounded_integer(id, 2, 2147483647) or int(id) in seen: return false
		seen.append(int(id))
	return true
