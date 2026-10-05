class_name EnduranceSaveValidation
extends RefCounted
## Bounded optional running state; older saves begin with a full reserve.

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("exhausted") is bool: return false
	for key in ["current", "rest"]:
		var number: Variant = value.get(key)
		if not (number is float or number is int) or not is_finite(float(number)): return false
		if number < 0.0 or number > (100.0 if key == "current" else 1.2): return false
	return true
