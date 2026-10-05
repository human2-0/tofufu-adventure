class_name MapSaveValidation
extends RefCounted
## Accept canonical original/expanded exploration without decoding malformed text.

static func valid(value: Variant) -> bool:
	if not value is String or value.length() not in [10120, 20468, 33920]: return false
	if RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$").search(value) == null: return false
	var bytes := Marshalls.base64_to_raw(value)
	return bytes.size() in [7589, 15350, 25440] and Marshalls.raw_to_base64(bytes) == value
