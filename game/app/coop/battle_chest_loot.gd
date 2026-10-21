class_name BattleChestLoot
extends RefCounted
## Every chest uses the same rarity-weighted pool; its four distinct rolls never reroll.

static func contents(epoch: String, id: int) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = epoch.hash() ^ (id * 7919 + 34391)
	var pool: Array[int] = []
	for i in BattlePackWire.ITEMS.size(): pool.append(i + 1)
	var result: Array[int] = []
	for i in 4:
		var kind := BattleRarity.roll(rng, pool)
		result.append(kind)
		pool.erase(kind)
	return result

static func open(pack: BattlePack, slot: int, id: int) -> bool:
	var chests := pack.game.match_state.chests
	if id < 0 or id >= chests.size() or chests[id][4] != 0: return false
	var row: Array = chests[id]
	var at := Vector3(row[1], row[2], row[3])
	if not pack.reachable(slot, at, id): return false
	var available := BattlePackWire.DROPS - pack.game.match_state.drops.size()
	for drop: Array in pack.game.match_state.drops:
		if drop[5] == 0: available += 1
	if available < 4: return false
	var kinds := contents(pack.game.room.epoch, id)
	var forward := (pack.game.bodies[slot].position - at).normalized()
	forward.y = 0
	forward = Vector3.FORWARD if forward.is_zero_approx() else forward.normalized()
	var center := at + forward * 1.9
	for i in 4:
		var angle := i * TAU / 4.0 + PI * 0.25
		var where := center + Vector3(cos(angle), 0, sin(angle)) * 0.6
		var point := pack.drop_point(slot, where - pack.game.bodies[slot].position)
		pack.spawn(ItemStack.new(BattleItems.make(kinds[i]), 1), point)
	row[4] = 1
	pack.game.match_state.stats[slot][BattleRoundStats.CHESTS] += 1
	return true
