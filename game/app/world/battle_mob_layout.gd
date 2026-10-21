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
	for i in range(candidates.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = swap
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6, 2.2, 2.6)
	for chest: Array in candidates:
		for attempt in 12:
			var angle := rng.randf_range(0, TAU)
			var at := game.world.ground_point(chest[1] + cos(angle) * 14, chest[3] + sin(angle) * 14, 0.08)
			if at.y < -2: continue # Existing adventure enemies retire below Y = -4.
			if not BattlePlantLayout._flat(game, at) or not BattleChestLayout.clear(game, at, shape): continue
			if not _spaced(game, rows, at): continue
			at = at.snapped(Vector3.ONE * 0.001)
			var kind := rows.size() % 3
			var state: Array = [at.x, at.y, at.z, 0, 0, 0, BattleMobWire.HEALTH[kind], 0, 0]
			if kind == 1: state.append_array([65, 0, 1])
			if kind == 2: state.append_array([0, 1, 0, 0, 0, 0, 0, 0, 0])
			rows.append([kind, at.x, at.y, at.z, state, 0, 0, 0, 0, 0, -1, -1, [at.x, at.y, at.z, 0, 0, 0, 0, 0], str(rng.state), [0.75, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]])
			break
		if rows.size() == BattleMobWire.LIMIT: break
	game.mobs.present()

static func _spaced(game: BattleRoyaleGame, rows: Array, at: Vector3) -> bool:
	for site: Array in game.match_state.deployment.get("sites", []):
		if Vector2(at.x - site[0], at.z - site[2]).length_squared() < 144: return false
	for row: Array in rows:
		if Vector2(at.x - row[1], at.z - row[3]).length_squared() < 3600: return false
	return true
