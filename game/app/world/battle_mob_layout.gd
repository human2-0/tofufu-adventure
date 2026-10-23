class_name BattleMobLayout
extends RefCounted
## Seeded, spaced hunts beside loot routes, with dry ground and plant clearance.

static func populate(game: BattleRoyaleGame) -> void:
	var rows: Array = []
	var counts: Array = []
	counts.resize(game.bodies.size())
	counts.fill(0)
	game.match_state.mobs = [rows, counts]
	var rng := RandomNumberGenerator.new()
	rng.seed = game.room.epoch.hash() ^ 419231
	var candidates := game.match_state.chests.duplicate(true)
	# Deployment clearings also supply dry fallback routes in sparse coastal quarters.
	for site: Array in game.match_state.deployment.sites:
		candidates.append([-1, site[0], site[1], site[2]])
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	# Visit each quarter in turn so denser routes cannot starve a whole map region.
	var quarters: Array = [[], [], [], []]
	for chest: Array in candidates:
		var quarter := int(chest[1] >= BattleRing.CENTER.x) + 2 * int(chest[3] >= BattleRing.CENTER.y)
		quarters[quarter].append(chest)
	var candidate_count := candidates.size()
	candidates.clear()
	var index := 0
	while candidates.size() < candidate_count:
		for quarter: Array in quarters:
			if index < quarter.size(): candidates.append(quarter[index])
		index += 1
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6, 2.2, 2.6)
	var population := [0, 0, 0, 0]
	for pass_index in 2:
		for chest: Array in candidates:
			var quarter := _quarter(Vector3(chest[1], chest[2], chest[3]))
			if pass_index == 0 and population[quarter] >= 6: continue
			var at := _site(game, chest, rows, rng, shape)
			if at == Vector3.INF: continue
			var kind := rows.size() % 3
			var state: Array = [at.x, at.y, at.z, 0, 0, 0, BattleMobWire.HEALTH[kind], 0, 0]
			if kind == 1: state.append_array([65, 0, 1])
			if kind == 2: state.append_array([0, 1, 0, 0, 0, 0, 0, 0, 0])
			rows.append([kind, at.x, at.y, at.z, state, 0, 0, 0, 0, 0, -1, -1, [at.x, at.y, at.z, 0, 0, 0, 0, 0], str(rng.state), [0.75, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]])
			population[quarter] += 1
			if rows.size() == BattleMobWire.LIMIT: break
		if rows.size() == BattleMobWire.LIMIT: break
	BattleHonioSpawn.apply(game.room.epoch, rows)
	game.mobs.present()

static func _quarter(at: Vector3) -> int:
	return int(at.x >= BattleRing.CENTER.x) + 2 * int(at.z >= BattleRing.CENTER.y)

static func _site(game: BattleRoyaleGame, chest: Array, rows: Array, rng: RandomNumberGenerator, shape: BoxShape3D) -> Vector3:
	for attempt in 12:
		var angle := rng.randf_range(0, TAU)
		var at := game.world.ground_point(chest[1] + cos(angle) * 14, chest[3] + sin(angle) * 14, 0.08)
		if at.y < -2 or _quarter(at) != _quarter(Vector3(chest[1], chest[2], chest[3])): continue
		if not BattlePlantLayout._flat(game, at) or not BattleChestLayout.clear(game, at, shape): continue
		if _spaced(game, rows, at): return at.snapped(Vector3.ONE * 0.001)
	return Vector3.INF

static func _spaced(game: BattleRoyaleGame, rows: Array, at: Vector3) -> bool:
	for site: Array in game.match_state.deployment.get("sites", []):
		if Vector2(at.x - site[0], at.z - site[2]).length_squared() < 144: return false
	for row: Array in rows:
		if Vector2(at.x - row[1], at.z - row[3]).length_squared() < 3600: return false
	return true
