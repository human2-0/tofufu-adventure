class_name BattleWire
extends RefCounted
## Value-only compressed JSON. Bound both encoded and expanded data before parsing.

const MAX_RAW_BYTES: int = 196608
const MAX_WIRE_BYTES: int = 58000
const PREFIX: String = "Z6:"

static func encode(value: Dictionary) -> String:
	var raw := JSON.stringify(value).to_utf8_buffer()
	if raw.size() > MAX_RAW_BYTES: return ""
	var packed := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var result := PREFIX + str(raw.size()) + ":" + packed.hex_encode().sha256_text() + ":" + Marshalls.raw_to_base64(packed)
	return result if result.length() <= MAX_WIRE_BYTES else ""

static func text(blob: String) -> String:
	if blob.begins_with("{"):
		return blob if blob.to_utf8_buffer().size() <= MAX_RAW_BYTES else ""
	if blob.length() > MAX_WIRE_BYTES or not blob.begins_with(PREFIX): return ""
	var fields := blob.split(":", true, 3)
	if fields.size() != 4 or not fields[1].is_valid_int(): return ""
	var size := int(fields[1])
	if size < 2 or size > MAX_RAW_BYTES or fields[2].length() != 64: return ""
	var base64 := fields[3]
	if base64.length() % 4 != 0 or base64.length() < 12: return ""
	if RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$").search(base64) == null: return ""
	var packed := Marshalls.base64_to_raw(base64)
	if packed.size() < 6 or packed[0] != 120 or packed.hex_encode().sha256_text() != fields[2]: return ""
	var raw := packed.decompress(size, FileAccess.COMPRESSION_DEFLATE)
	return raw.get_string_from_utf8() if raw.size() == size else ""

static func packet(value: Dictionary) -> Dictionary:
	return {"kind": "br_state", "epoch": value.epoch, "term": value.term, "seq": value.seq, "blob": encode(value)}

static func restore(value: Dictionary) -> Dictionary:
	if not value.has("blob"): return value.duplicate()
	if not value.blob is String: return {}
	var parser := JSON.new()
	var source := text(value.blob)
	if source.is_empty() or parser.parse(source) != OK or not parser.data is Dictionary: return {}
	var result: Dictionary = parser.data
	for field in ["kind", "epoch", "term", "seq"]:
		if result.get(field) != value.get(field): return {}
	return result
