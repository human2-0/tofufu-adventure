class_name AngelBowProtocol
extends RefCounted
## Bounded values only; session code does not depend on combat classes.

static func valid(data: Dictionary) -> bool:
	for field in ["bow", "bow_fire"]:
		if data.has(field) and not data[field] is bool: return false
	if data.get("bow", false):
		for field in ["selected", "staff", "gun", "jet", "guard", "active", "paws", "nori", "pod"]:
			if data.get(field, false): return false
	for field in {"bow_reload": 2.0, "bow_charge": 1.25, "bow_cooldown": 6.0}:
		if data.has(field) and (not ExplorationProtocol.number(data[field], {"bow_reload": 2.0, "bow_charge": 1.25, "bow_cooldown": 6.0}[field]) or data[field] < 0): return false
	for field in ["bow_shot", "bow_burst"]:
		if data.has(field) and not ExplorationProtocol.sequence(data[field]): return false
	for field in ["bow_origin", "bow_at", "bow_velocity"]:
		if data.has(field) and not ExplorationProtocol.vector(data[field], 3, 96 if field == "bow_velocity" else 1000): return false
	if data.has("bow_velocity") and Vector3(data.bow_velocity[0], data.bow_velocity[1], data.bow_velocity[2]).length() > 96.001: return false
	if data.get("bow_charge", 0) > 0 and (not data.get("bow", false) or data.get("bow_reload", 0) > 0 or data.get("bow_cooldown", 0) > 0): return false
	return true
