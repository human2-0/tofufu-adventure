class_name BattleMobShotWire
extends RefCounted
## One bounded telegraph and active swept projectile per hunt; no remote objects.
static func valid(value: Variant) -> bool:
	if not value is Array or value.size() != 13: return false
	if not BattleProtocol.number(value[0], 0, 5) or not BattleProtocol.number(value[1], 0, 1): return false
	for i in range(2, 5):
		if not BattleProtocol.number(value[i], -1, 1): return false
	if Vector3(value[2], value[3], value[4]).length_squared() > 1.004: return false
	for i in range(5, 8):
		if not BattleProtocol.number(value[i], -1000, 1000): return false
	for i in range(8, 11):
		if not BattleProtocol.number(value[i], -40, 40): return false
	if Vector3(value[8], value[9], value[10]).length_squared() > 1601: return false
	return BattleProtocol.number(value[11], 0, 4) and BattleProtocol.integer(value[12], 0, 1000000)
