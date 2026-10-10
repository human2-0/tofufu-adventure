class_name TofuPuzzleProtocol
extends RefCounted
## Bounded wire intent. The app converts accepted fields to a quest command.

const ACTION_COUNT: int = 18
const PASSWORD_ACTION: int = 5
const CUT_ACTION: int = 11
const MAX_COUNTER: int = 2147483647
const MAX_ID_LENGTH: int = 48
const MAX_PASSWORD_LENGTH: int = 32
const MAX_CUT_POSITION: float = 1000.0
const REQUIRED: Array[String] = ["action", "target_id", "object_id", "run_id", "attempt_id", "sequence", "expected_revision"]
const OPTIONAL: Array[String] = ["text", "cuts"]
const STATION_IDS: Array[String] = ["lab_terminal", "shift_note", "coagulation_tank", "traditional_press", "modern_press", "cutter", "soft", "firm", "extra_firm", "accessible", "standard"]
const SACK_IDS: Array[String] = ["sack_edamame", "sack_mature", "sack_high_fat"]
const INTAKE_IDS: Array[String] = ["intake_chilled", "intake_tofu", "intake_oil"]
const STONE_IDS: Array[String] = ["stone_1", "stone_2", "stone_3"]

static func command(packet: Variant) -> Dictionary:
	if not valid(packet): return {}
	var result: Dictionary = {}
	for field: String in REQUIRED: result[field] = packet[field]
	if packet.action == PASSWORD_ACTION: result["text"] = packet.text
	if packet.action == CUT_ACTION: result["cuts"] = packet.cuts.duplicate()
	return result

static func valid(packet: Variant) -> bool:
	if not packet is Dictionary: return false
	if packet.size() < REQUIRED.size() or packet.size() > REQUIRED.size() + 1: return false
	for field: String in REQUIRED:
		if not packet.has(field): return false
	for field: Variant in packet:
		if not (field is String or field is StringName): return false
		if String(field) not in REQUIRED and String(field) not in OPTIONAL: return false
	if not _counter(packet.action, 0) or packet.action >= ACTION_COUNT: return false
	for field: String in ["run_id", "attempt_id", "sequence"]:
		if not _counter(packet[field], 1): return false
	if not _counter(packet.expected_revision, 0): return false
	if not _id(packet.target_id) or not _id(packet.object_id): return false
	if packet.action == PASSWORD_ACTION:
		return packet.size() == REQUIRED.size() + 1 and packet.get("text") is String \
			and packet.text.length() <= MAX_PASSWORD_LENGTH
	if packet.action == CUT_ACTION:
		if packet.size() != REQUIRED.size() + 1 or not packet.get("cuts") is Array: return false
		if packet.cuts.size() != 5: return false
		for cut: Variant in packet.cuts:
			if not (cut is int or cut is float) or not is_finite(float(cut)): return false
			if absf(float(cut)) > MAX_CUT_POSITION: return false
		return true
	return packet.size() == REQUIRED.size()

static func _counter(value: Variant, minimum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and value >= minimum and value <= MAX_COUNTER

static func _id(value: Variant) -> bool:
	if not value is String or value.length() > MAX_ID_LENGTH: return false
	if value.is_empty() or value in STATION_IDS: return true
	if value in SACK_IDS or value in INTAKE_IDS or value in STONE_IDS: return true
	if value in ["stash_mill", "stash_press", "stash_pack"]: return true
	if value.length() == 1 and value in ["0", "1", "2", "3", "4", "5"]: return true
	if value.begins_with("container_"):
		var suffix: String = value.trim_prefix("container_")
		return suffix.length() == 2 and _digits(suffix) and int(suffix) < 20
	return _block_id(value)

static func _block_id(value: String) -> bool:
	if not value.begins_with("batch_"): return false
	var parts: PackedStringArray = value.split("_")
	if parts.size() not in [4, 5]: return false
	if not _positive_token(parts[1]) or not _positive_token(parts[2]): return false
	if parts.size() == 4: return parts[3] == "block"
	return parts[3] == "retry" and _positive_token(parts[4])

static func _positive_token(value: String) -> bool:
	return not value.is_empty() and value.length() <= 10 and _digits(value) and int(value) > 0

static func _digits(value: String) -> bool:
	for character: String in value:
		if character not in "0123456789": return false
	return true
