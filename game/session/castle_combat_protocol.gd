class_name CastleCombatProtocol
extends RefCounted
## Finite guardian stances and bounded spell records shared by live castle snapshots.

static func guardian(value: Variant, index: int) -> bool:
	if not value is Dictionary: return false
	var row: Variant = value.get("body")
	if not numbers(row, 16, 2147483647): return false
	if not integer(row[4], 0, 80) or row[3] < 0 or row[3] > 360 + (index / 3) * 60: return false
	if row[5] < 0 or row[5] > 0.9 or row[6] < 0 or row[6] > 1.6 or absf(row[7]) > PI: return false
	if absf(row[0] - 316) > 27 or absf(row[2] - 334) > 27 or absf(row[1] - (4.4 + (index / 3) * 8)) > 1: return false
	if not integer(row[8], 0, 2) or row[9] < 0 or row[9] > 0.2 or row[10] < 0 or row[10] > 2.6: return false
	if row[11] < 0 or row[11] > 0.8 or not integer(row[12], 0, 2147483647) or row[13] not in [-1.0, 1.0]: return false
	if Vector2(row[14], row[15]).length_squared() > 1.01: return false
	return spells(value.get("spells"), 6, 0)

static func spells(value: Variant, bolt_limit: int, field_limit: int) -> bool:
	if not value is Dictionary: return false
	if not value.get("bolts") is Array or value.bolts.size() > bolt_limit or not value.get("fields") is Array or value.fields.size() > field_limit: return false
	for bolt: Variant in value.bolts:
		if not numbers(bolt, 8, 1000) or not integer(bolt[7], 0, 1): return false
		if Vector3(bolt[3], bolt[4], bolt[5]).length_squared() > 34.01 * 34.01 or bolt[6] < 0 or bolt[6] > 3.5: return false
	for field: Variant in value.fields:
		if not numbers(field, 8, 1000) or not integer(field[0], 0, 1): return false
		if field[4] < -3 or field[4] > 4 or field[5] < 0 or field[5] > 4 or field[6] < 0 or field[6] > 1 or field[7] < 0 or field[7] > 20: return false
	return true

static func numbers(value: Variant, count: int, bound: float) -> bool:
	if not value is Array or value.size() != count: return false
	for item: Variant in value:
		if not (item is int or item is float) or not is_finite(float(item)) or absf(item) > bound: return false
	return true

static func integer(value: Variant, lo: int, hi: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= lo and value <= hi and value == floorf(value)
