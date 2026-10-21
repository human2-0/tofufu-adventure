class_name BattleProtocol
extends RefCounted
## Independent, bounded battle protocol. Arrays contain values, never objects.

const VERSION: int = 10
const BUILD: int = PlaytestRoom.GAME_VERSION
const HUMAN_CAPACITY: int = 20
const CAPACITY: int = 70
const INPUT_DELAY: float = 0.10
const INPUT_TTL: float = 0.30
const ROW_SIZE: int = 24

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= low and float(value) <= high

static func integer(value: Variant, low: int, high: int) -> bool:
	return number(value, low, high) and float(value) == floorf(float(value))

static func key(value: Variant) -> bool:
	return value is String and value.length() == 64 and value.is_valid_hex_number(false) and value == value.to_lower()

static func token(value: Variant) -> bool:
	return value is String and value.length() == 24 and value.is_valid_hex_number(false) and value == value.to_lower()

static func command(value: Variant) -> bool:
	if not value is Array or value.size() not in [5, 6, 7, 8]: return false
	for i in 4:
		if not number(value[i], -1, 1): return false
	if value.size() >= 6 and not number(value[5], -1, 1): return false
	if value.size() >= 7 and not integer(value[6], 0, 2): return false
	if value.size() == 8 and not number(value[7], 0.1, 160): return false
	return integer(value[4], 0, 2097151) and Vector2(value[0], value[1]).length_squared() <= 1.003

static func roster(value: Variant) -> bool:
	if not value is Array or value.is_empty() or value.size() > HUMAN_CAPACITY: return false
	var seen: Dictionary = {}
	for row: Variant in value:
		if not row is Dictionary or row.size() != 3: return false
		if not key(row.get("key")) or seen.has(row.key): return false
		if not row.get("name") is String or row.name.is_empty() or row.name.length() > 24: return false
		if not integer(row.get("skin"), 0, 7): return false
		seen[row.key] = true
	return true

static func snapshot(value: Dictionary) -> bool:
	if not integer(value.get("seq"), 1, 2147483647): return false
	if not number(value.get("time"), 0, 900) or not integer(value.get("winner"), -2, CAPACITY - 1): return false
	var rows: Variant = value.get("actors")
	if not BattleOptions.valid(value.get("options")): return false
	if not rows is Array or rows.size() < 2 or rows.size() > CAPACITY: return false
	if int(value.winner) >= rows.size(): return false
	if not value.has("circle") or not value.has("stats"): return false
	if value.has("circle"):
		if not ExplorationProtocol.vector(value.circle, 2, 300): return false
		if Vector2(value.circle[0], value.circle[1]).distance_to(BattleRing.CENTER) > 240: return false
	if value.has("stats") and not BattleRoundStats.valid(value.stats, rows.size()): return false
	if value.has("mobs") and not BattleMobWire.valid(value.mobs, rows.size()): return false
	if value.has("deployment") and not BattleDeploymentState.valid(value.deployment, rows.size(), value.options): return false
	for row: Variant in rows:
		if not row is Array or row.size() != ROW_SIZE: return false
		for i in 8:
			if not number(row[i], -1000, 1000): return false
		if not number(row[8], 0, 100) or not number(row[9], 0, 100): return false
		for bound: Array in [[10, 0, 11], [11, 0, 30], [12, 0, CAPACITY - 1], [13, 0, CAPACITY], [14, 0, 100000], [15, 0, 1], [16, 0, 1999], [17, 0, 1]]:
			if not integer(row[bound[0]], bound[1], bound[2]): return false
		if not integer(row[18], 0, 2): return false
		if not number(row[19], -1, 1): return false
		if not number(row[20], -1, 1) or not number(row[21], -1, 1): return false
		# Checkpoints round each component to 0.001; allow that quantisation error.
		if Vector2(row[20], row[21]).length_squared() > 1.003: return false
		for index in [22, 23]:
			if not integer(row[index], 0, 11): return false
	if value.has("combat") and (not BattleCombatWire.roster(value.combat) or value.combat.size() != rows.size()): return false
	if value.has("pack"):
		if not BattlePackWire.packs(value.pack) or value.pack.size() != rows.size() or not BattlePackWire.world(value.get("chests"), value.get("drops")): return false
	var loot: Variant = value.get("loot")
	if not loot is Array or loot.size() > 160: return false
	for row: Variant in loot:
		if not row is Array or row.size() != 6: return false
		if not integer(row[0], 0, 10000) or not integer(row[4], 0, 13) or not integer(row[5], 0, 1): return false
		for i in range(1, 4):
			if not number(row[i], -1000, 1000): return false
	return true
