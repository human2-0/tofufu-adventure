class_name BattleHuntLoot
extends RefCounted
## Guaranteed food plus useful equipment, seeded once per finite hunt.

static func contents(epoch: String, id: int, kind: int) -> Array[int]:
	var rng := RandomNumberGenerator.new()
	rng.seed = epoch.hash() ^ (id * 7919) ^ 118231
	if kind == 3:
		return [28, 27, 33, BattleRarity.roll(rng, BattleRarity.pool(12, 23), [0, 0, 100])]
	var result: Array[int] = [28 if kind > 0 else 27]
	if kind == 0: result.append(BattleRarity.roll(rng, BattleRarity.pool(12, 23), [55, 40, 5]))
	elif kind == 1:
		result.append(BattleRarity.roll(rng, BattleRarity.pool(12, 23), [20, 60, 20]))
		result.append(BattleRarity.roll(rng, BattleRarity.pool(3, 11), [0, 80, 20]))
	else: result.append(BattleRarity.roll(rng, BattleRarity.pool(3, 11), [0, 80, 20]) if rng.randf() < 0.65 else rng.randi_range(25, 26))
	return result

static func release(game: BattleRoyaleGame, id: int) -> void:
	var row: Array = game.match_state.mobs[0][id]
	if row[9] != 1: return
	var kinds := contents(game.room.epoch, id, int(row[0]))
	var available := BattlePackWire.DROPS - game.match_state.drops.size()
	for drop: Array in game.match_state.drops:
		if drop[5] == 0: available += 1
	if available < kinds.size(): return # Retain the pending claim across snapshots/migration.
	var at := Vector3(row[4][0], row[4][1], row[4][2])
	if game.world.is_water(at): at = Vector3(row[1], row[2], row[3])
	for i in kinds.size():
		var angle := i * TAU / kinds.size()
		var point := at + Vector3(cos(angle), 0, sin(angle)) * 0.7
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point + Vector3.DOWN * 64, 1)
		var floor_hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		point = floor_hit.position + Vector3.UP * 0.05 if not floor_hit.is_empty() else Vector3(row[1], row[2], row[3])
		if game.world.is_water(point): point = Vector3(row[1], row[2], row[3])
		game.pack.spawn(ItemStack.new(BattleItems.make(kinds[i]), 2 if kinds[i] == 27 else 1), point)
	row[9] = 2
