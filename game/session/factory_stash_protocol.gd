class_name FactoryStashProtocol
extends RefCounted
## Bounded manufacturing treasure claims; no gameplay dependencies.

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 2: return false
	for field: String in ["opened", "revision"]:
		var number: Variant = value.get(field)
		if not (number is int or number is float) or not is_finite(float(number)) or number != floorf(number): return false
	if value.opened < 0 or value.opened > 7 or value.revision < 0 or value.revision > 3: return false
	var bits: int = 0
	for index in 3:
		if (int(value.opened) & (1 << index)) != 0: bits += 1
	return bits == int(value.revision)
