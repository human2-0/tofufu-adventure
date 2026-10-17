class_name BengalCombatProtocol
extends RefCounted
## Bounded optional training-weapon state for host snapshots and checkpoints.

static func valid(data: Dictionary) -> bool:
	if data.has("paws") and not data.paws is bool: return false
	if data.get("paws", false):
		for field in ["selected", "staff", "gun", "jet", "guard", "active", "nori", "pod"]:
			if data.get(field, false): return false
	if data.has("claw_cooldown") and (not ExplorationProtocol.number(data.claw_cooldown, 8) or data.claw_cooldown < 0): return false
	if data.has("claw_sequence") and not ExplorationProtocol.sequence(data.claw_sequence): return false
	if data.has("claw_origin") and not ExplorationProtocol.vector(data.claw_origin, 3, 1000): return false
	if data.has("claw_aim") and not ExplorationProtocol.vector(data.claw_aim, 2, 1): return false
	for field in ["claw_charging", "claw_dashing"]:
		if data.has(field) and not data[field] is bool: return false
	for field in {"claw_charge": 2.0, "claw_remaining": 0.36}:
		if data.has(field) and (not ExplorationProtocol.number(data[field], 2.0 if field == "claw_charge" else 0.36) or data[field] < 0.0): return false
	if data.has("claw_launch") and not ExplorationProtocol.sequence(data.claw_launch): return false
	if data.get("claw_charging", false) and data.get("claw_dashing", false): return false
	if (data.get("claw_charging", false) or data.get("claw_dashing", false)) and not data.get("paws", false): return false
	return true
