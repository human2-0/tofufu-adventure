class_name BattleChestLoot
extends RefCounted
## Fixed tier rolls independent of region and opening order; reserve the full spill.

const CHUNK_CHANCE: Array[float] = [0.10, 0.35, 0.70]
const WEIGHTS: Array = [[72, 25, 3], [20, 65, 15], [0, 25, 75]]

static func contents(epoch: String, id: int, tier: int = 0) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = epoch.hash() ^ (id * 7919 + 34391)
	var pool := BattleRarity.pool(1, 32)
	var result: Array[int] = []
	# Each route offers a weapon, protection/storage, food and one flexible choice.
	for bounds: Array in [[1, 11], [12, 26], [27, 32], [1, 32]]:
		var choices: Array[int] = []
		for kind in pool:
			if kind >= bounds[0] and kind <= bounds[1]: choices.append(kind)
		var weights: Array[int] = []
		weights.assign(WEIGHTS[tier])
		if bounds[0] == 27: weights = [100, 0, 0]
		if tier == 2 and result.size() < 2: weights = [0, 0, 100]
		var kind := BattleRarity.roll(rng, choices, weights)
		result.append(kind)
		pool.erase(kind)
	if rng.randf() < CHUNK_CHANCE[tier]: result.append(33)
	return result

static func open(pack: BattlePack, slot: int, id: int) -> bool:
	var chests := pack.game.match_state.chests
	if id < 0 or id >= chests.size() or chests[id][4] != 0: return false
	var row: Array = chests[id]
	var at := Vector3(row[1], row[2], row[3])
	if not pack.reachable(slot, at, id): return false
	var kinds := contents(pack.game.room.epoch, id, int(row[5]))
	var available := BattlePackWire.DROPS - pack.game.match_state.drops.size()
	for drop: Array in pack.game.match_state.drops:
		if drop[5] == 0: available += 1
	if available < kinds.size(): return false
	var forward := (pack.game.bodies[slot].position - at).normalized()
	forward.y = 0
	forward = Vector3.FORWARD if forward.is_zero_approx() else forward.normalized()
	var center := at + forward * 1.9
	for i in kinds.size():
		var angle := i * TAU / kinds.size() + PI * 0.25
		var where := center + Vector3(cos(angle), 0, sin(angle)) * 0.6
		var point := pack.drop_point(slot, where - pack.game.bodies[slot].position)
		pack.spawn(ItemStack.new(BattleItems.make(kinds[i]), 1), point)
	row[4] = 1
	pack.game.match_state.stats[slot][BattleRoundStats.CHESTS] += 1
	return true
