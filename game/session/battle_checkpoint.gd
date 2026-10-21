class_name BattleCheckpoint
extends RefCounted
## Resumable, value-only state. Bound the serialized payload before parsing it.

const MAX_BYTES: int = BattleWire.MAX_RAW_BYTES
const MOTOR_SIZE: int = 23

static func decode(blob: Variant, members: Array) -> Dictionary:
	if not blob is String or blob.length() > MAX_BYTES or blob.to_utf8_buffer().size() > MAX_BYTES: return {}
	var parser := JSON.new()
	var source := BattleWire.text(blob)
	if source.is_empty() or parser.parse(source) != OK: return {}
	var data: Variant = parser.data
	if not data is Dictionary or data.size() != 11 + int(data.has("mobs")) + int(data.has("circle")) + int(data.has("stats")) + int(data.has("deployment")) + int(data.has("combat")) + (3 if data.has("pack") else 0) or not BattleProtocol.snapshot(data): return {}
	if data.actors.size() != BattleOptions.seats(data.options, members.size()): return {}
	if not BattleProtocol.integer(data.get("tick"), 0, 1000000): return {}
	for field: String in ["cooldowns", "reloads"]:
		var values: Variant = data.get(field)
		if not values is Array or values.size() != data.actors.size(): return {}
		for value: Variant in values:
			if not BattleProtocol.number(value, 0, 2): return {}
	var motors: Variant = data.get("motors")
	if not motors is Array or motors.size() != data.actors.size(): return {}
	for motor: Variant in motors:
		if not motor is Array or motor.size() != MOTOR_SIZE: return {}
		for value: Variant in motor:
			if not BattleProtocol.number(value, -100, 100): return {}
		for index: int in [0, 1, 5, 7, 17, 18, 22]:
			if not BattleProtocol.integer(motor[index], 0, 1): return {}
		for index: int in [2, 3, 4, 6, 8, 9, 10, 11, 15, 16, 19]:
			if motor[index] < 0: return {}
		if motor[15] > 100 or motor[16] > 1.2 or motor[19] > 0.24: return {}
		if Vector3(motor[12], motor[13], motor[14]).length_squared() > 1.003: return {}
	var voters: Variant = data.get("voters")
	if not voters is Array or voters.is_empty() or voters.size() > members.size(): return {}
	var seen: Dictionary = {}
	for key: Variant in voters:
		if not BattleProtocol.key(key) or seen.has(key): return {}
		var slot := -1
		for i in members.size():
			if members[i].key == key: slot = i
		if slot < 0: return {}
		seen[key] = true
	data.options = BattleOptions.canonical(data.options)
	return data
