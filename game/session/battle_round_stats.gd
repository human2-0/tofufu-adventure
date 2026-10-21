class_name BattleRoundStats
extends RefCounted
## Bounded authoritative match achievements; rewards are cosmetic and local only.

const DAMAGE: int = 0
const TAKEN: int = 1
const CHESTS: int = 2
const FOOD: int = 3
const SECONDS: int = 4
const QUIET: int = 5

static func create(count: int) -> Array:
	var rows: Array = []
	for slot in count: rows.append([0.0, 0.0, 0, 0, 0.0, 0.0])
	return rows

static func valid(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count: return false
	for row: Variant in value:
		if not row is Array or row.size() != 6: return false
		for index in [DAMAGE, TAKEN]:
			if not BattleProtocol.number(row[index], 0, 100000): return false
		if not BattleProtocol.integer(row[CHESTS], 0, 80) or not BattleProtocol.integer(row[FOOD], 0, 1999): return false
		if not BattleProtocol.number(row[SECONDS], 0, 900): return false
		if not BattleProtocol.number(row[QUIET], 0, 8): return false
	return true

static func goals(state: BattleMatch, slot: int) -> Array[int]:
	var row: Array = state.stats[slot]
	return [mini(3, int(row[CHESTS])), mini(100, floori(row[DAMAGE])), mini(90, floori(row[SECONDS]))]

static func summary(state: BattleMatch, slot: int) -> Dictionary:
	var actor: Array = state.rows[slot]
	var row: Array = state.stats[slot]
	var progress := goals(state, slot)
	var done := int(progress[0] >= 3) + int(progress[1] >= 100) + int(progress[2] >= 90)
	var rank := int(actor[13])
	var won := state.winner >= 0 and BattleTeams.allies(state.options, slot, state.winner)
	var xp := mini(60, floori(row[SECONDS] / 5)) + int(actor[12]) * 25 + done * 20
	if rank > 0: xp += 15 + (100 if won else (40 if rank <= 3 else 0))
	return {"rank": rank, "kills": int(actor[12]), "damage": floori(row[DAMAGE]), "chests": int(row[CHESTS]),
		"seconds": floori(row[SECONDS]), "goals": done, "xp": xp, "won": won}
