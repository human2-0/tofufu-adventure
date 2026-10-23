class_name BattleMobWire
extends RefCounted
## Finite PvE population; separate from survivor seats, KOs and victory.
const LIMIT: int = 24
const ROW_SIZE: int = 15
const HEALTH: Array[int] = [100, 170, 110, 320]

static func valid(value: Variant, survivors: int) -> bool:
	if not value is Array: return false
	if value.is_empty(): return true # Pure match rules need no world composition.
	if value.size() != 2 or not value[0] is Array or value[0].size() > LIMIT: return false
	if not value[1] is Array or value[1].size() != survivors: return false
	var total := 0
	var honios := 0
	for count: Variant in value[1]:
		if not BattleProtocol.integer(count, 0, LIMIT): return false
		total += int(count)
	if total > value[0].size(): return false
	var credited: Array[int] = []
	credited.resize(survivors)
	credited.fill(0)
	for row: Variant in value[0]:
		if not row is Array or row.size() != ROW_SIZE or not BattleProtocol.integer(row[0], 0, 3): return false
		if row[0] == 3: honios += 1
		if honios > 1: return false
		for i in range(1, 4):
			if not BattleProtocol.number(row[i], -1000, 1000): return false
		var state: Variant = row[4]
		if not state is Array or state.size() != [9, 12, 18, 9][int(row[0])]: return false
		for i in state.size():
			if not BattleProtocol.number(state[i], -1000, 1000): return false
		if not BattleProtocol.number(state[6], 0, HEALTH[int(row[0])]): return false
		if not BattleProtocol.number(state[7], 0, 900) or not BattleProtocol.number(state[8], 0, 2): return false
		if row[0] == 1 and not BattleProtocol.number(state[9], 0, 65): return false
		if row[0] == 2 and not BattleProtocol.number(state[17], 0, 1.5): return false
		for i in range(5, 9):
			if not BattleProtocol.number(row[i], 0, 20): return false
		if row[0] == 3 and not BattleProtocol.number(row[6], 0, 2.5): return false
		if not BattleProtocol.integer(row[9], 0, 3) or not BattleProtocol.integer(row[10], -1, survivors - 1): return false
		if not BattleProtocol.integer(row[11], -1, survivors - 1): return false
		if (state[6] > 0) != (row[9] == 0): return false
		if (state[7] == 0) != (row[9] == 0): return false
		if int(row[9]) in [1, 2]:
			if row[10] < 0: return false
			credited[int(row[10])] += 1
		if not row[12] is Array or row[12].size() != 8: return false
		for part: Variant in row[12]:
			if not BattleProtocol.number(part, -1000, 1000): return false
		if not BattleProtocol.number(row[12][3], 0, 10) or not BattleProtocol.number(row[12][7], 0, 4): return false
		if row[0] == 3:
			if not BattleHonioWire.valid(row[14]): return false
		elif not BattleMobShotWire.valid(row[14]): return false
		# RNG is signed 64-bit; a string preserves every bit through JSON peers.
		if not row[13] is String or row[13].length() > 20 or not row[13].is_valid_int(): return false
		var digits: String = row[13].trim_prefix("-")
		var limit := "9223372036854775808" if row[13].begins_with("-") else "9223372036854775807"
		if digits.length() > 19 or (digits.length() == 19 and digits > limit): return false
		if str(int(row[13])) != row[13]: return false
	for slot in survivors:
		if credited[slot] != value[1][slot]: return false
	return true
