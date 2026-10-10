class_name CastleTreasureProtocol
extends RefCounted
## Optional legacy fields; finite bit masks and up to 32 durable player identities.

static func valid(trial: Dictionary) -> bool:
	var opened: Variant = trial.get("opened_chests", 0)
	var claims: Variant = trial.get("treasure_claims", {})
	if not _mask(opened) or not claims is Dictionary or claims.size() > 32: return false
	for key: Variant in claims:
		if not _key(key): return false
		if key != key.to_lower() or not _mask(claims[key]) or int(claims[key]) & ~int(opened) != 0: return false
	var action: Variant = trial.get("last_action", -1)
	if not (action is int or action is float) or not is_finite(float(action)) or action != floorf(action) or action < -1 or action > 11: return false
	var revision: Variant = trial.get("feedback_revision", 0)
	return trial.get("accepted", false) is bool and CastleCombatProtocol.integer(revision, 0, 2147483647)

static func _key(value: Variant) -> bool:
	if not value is String: return false
	if value == "solo": return true
	if value.length() != 64: return false
	for character in value:
		if character not in "0123456789abcdef": return false
	return true

static func _mask(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floorf(value) and value >= 0 and value <= 4095
