class_name BattleHonioSpawn
extends RefCounted
## One optional Easter egg replaces a hunt; seeded independently from chest odds.
const CHANCE: float = 0.25

static func apply(epoch: String, rows: Array) -> void:
	var id := site(epoch, rows.size())
	if id < 0: return
	var row: Array = rows[id]
	row[0] = 3
	row[4] = row[4].slice(0, 9)
	row[4][6] = BattleMobWire.HEALTH[3]
	row[6] = 0
	row[7] = 0
	row[8] = 0
	row[14] = BattleHonioWire.initial()

static func site(epoch: String, count: int) -> int:
	if count <= 0: return -1
	var rng := RandomNumberGenerator.new()
	rng.seed = epoch.hash() ^ 173551
	if rng.randf() >= CHANCE: return -1
	# Rotate all existing dry sites equally; never privilege the map centre.
	return rng.randi_range(0, count - 1)
