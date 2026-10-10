class_name ReplicaWorldChanges
extends RefCounted
## Per-session immutable comparison records; simulation/packet rates stay unchanged.

var _values: Dictionary[String, Variant] = {}
var applied: int = 0
var skipped: int = 0

func changed(field: String, value: Variant) -> bool:
	if _values.has(field) and _values[field] == value:
		skipped += 1
		return false
	_values[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	applied += 1
	return true
