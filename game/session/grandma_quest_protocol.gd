class_name GrandmaQuestProtocol
extends RefCounted
## Fixed quest schema for character snapshots and co-op checkpoints.

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() not in [6, 8] or value.get("version") != 1 or value.get("id") != "cull_slimes": return false
	for field: String in ["status", "armored_status"]:
		if not ExplorationProtocol.sequence(value.get(field)) or value[field] > 3: return false
	for field: String in ["current_count", "armored_count"]:
		if not ExplorationProtocol.sequence(value.get(field)) or value[field] > 50: return false
	if value.size() == 8:
		if not ExplorationProtocol.sequence(value.get("god_status")) or value.god_status > 3: return false
		if not ExplorationProtocol.sequence(value.get("god_count")) or value.god_count > 200: return false
		if not _pair(value.god_status, value.god_count, 200): return false
	return _pair(value.status, value.current_count) and _pair(value.armored_status, value.armored_count)

static func _pair(status: int, count: int, target: int = 50) -> bool:
	if status == 0: return count == 0
	if status == 1: return count < target
	return count == target
