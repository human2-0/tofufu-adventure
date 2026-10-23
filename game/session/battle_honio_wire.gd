class_name BattleHonioWire
extends RefCounted
## Thirteen bounded melee values in the kind-specific skill slot; never a shot.
static func initial() -> Array:
	return [3, 1.25, 0, 0, 1, 0, 1, 0, 0, 0, -1, 0, 0]

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() != 13: return false
	if not BattleProtocol.integer(value[0], 0, 3): return false
	if not BattleProtocol.number(value[1], 0, 2) or not BattleProtocol.number(value[2], 0, 4.5): return false
	for i in range(3, 7):
		if not BattleProtocol.number(value[i], -1, 1): return false
	for i in [3, 5]:
		if absf(Vector2(value[i], value[i + 1]).length_squared() - 1) > 0.006: return false
	if not BattleProtocol.integer(value[7], 0, 1000000) or not BattleProtocol.integer(value[8], 0, 2): return false
	if not BattleProtocol.number(value[9], 0, 0.3) or not BattleProtocol.integer(value[10], -1, 4): return false
	if value[0] == 0 and value[1] != 0: return false
	if value[0] == 1 and value[1] > [0.5, 0.8, 1.0][int(value[8])]: return false
	if value[0] == 2 and (value[8] != 1 or value[1] > 0.58): return false
	if value[10] == -1 and value[12] != 0: return false
	return BattleProtocol.integer(value[11], 0, 1) and BattleProtocol.number(value[12], 0, 2.4)
