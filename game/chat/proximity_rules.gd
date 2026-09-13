class_name ProximityRules
extends RefCounted
## Bounded chat values and per-sender admission; positions come from the host.

const NEAR: float = 12.0
const YELL: float = 36.0
const SAMPLES: int = 1600
static var _pcm_pattern := RegEx.create_from_string("^[A-Za-z0-9+/]{4267}=$")
var _last: Dictionary = {}
var _sequence: Dictionary = {}
var _tokens: Dictionary = {}

static func clean(value: String) -> String:
	var result := ""
	for character in value:
		var code := character.unicode_at(0)
		if code >= 32 and code != 127 and not (code >= 0x202a and code <= 0x202e):
			result += character
	return result.strip_edges().left(240)

static func valid(data: Dictionary) -> bool:
	if not data.get("sequence") is int and not data.get("sequence") is float: return false
	var number := float(data.sequence)
	if not is_finite(number) or number != floor(number) or number < 0 or number > 2147483647: return false
	if data.get("type") == "chat_text":
		return data.get("text") is String and data.text.length() <= 240 and not clean(data.text).is_empty() and data.get("yell") is bool
	if data.get("type") == "chat_voice":
		if not data.get("pcm") is String or data.pcm.length() != 4268: return false
		if _pcm_pattern.search(data.pcm) == null: return false
		var bytes := Marshalls.base64_to_raw(data.pcm)
		return bytes.size() == SAMPLES * 2 and Marshalls.raw_to_base64(bytes) == data.pcm
	return false

func accept(key: String, data: Dictionary, now: int, limit_rate: bool = true) -> bool:
	if not valid(data): return false
	var id := key + str(data.type)
	if int(data.sequence) <= int(_sequence.get(id, -1)): return false
	var elapsed := now - int(_last.get(id, -10000))
	if limit_rate and data.type == "chat_text" and elapsed < 700: return false
	if limit_rate and data.type == "chat_voice":
		var tokens := minf(3, float(_tokens.get(id, 3.0)) + elapsed / 100.0)
		if tokens < 1: return false
		_tokens[id] = tokens - 1
	_sequence[id] = int(data.sequence)
	_last[id] = now
	return true

func forget(key: String) -> void:
	for kind in ["chat_text", "chat_voice"]:
		_tokens.erase(key + kind)
		_last.erase(key + kind)
		_sequence.erase(key + kind)

static func nearby(from: Vector3, to: Vector3, yell: bool = false) -> bool:
	return Vector2(from.x - to.x, from.z - to.z).length() <= (YELL if yell else NEAR)
