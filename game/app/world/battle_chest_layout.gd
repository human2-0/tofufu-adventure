class_name BattleChestLayout
extends RefCounted
## One seeded chest per land cell, with collision clearance and a minimum gap.
const COLUMNS: int = 10
const ROWS: int = 8
const GAP: float = 28.0

static func populate(game: BattleRoyaleGame) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = game.room.epoch.hash() ^ 832071
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.1, 1.6, 1.7)
	for z in ROWS:
		for x in COLUMNS:
			for attempt in 24:
				var px := -342.0 + (x + rng.randf_range(0.12, 0.88)) * 64
				var pz := -342.0 + (z + rng.randf_range(0.12, 0.88)) * 80
				var at := game.world.ground_point(px, pz, 0.08)
				if Vector2(px, pz).distance_to(BattleRing.CENTER) > 385 or game.world.is_water(at): continue
				var nearby := false
				for actor: Player in game.bodies:
					if actor.position.distance_squared_to(at) < 16: nearby = true
				for site: Array in game.match_state.deployment.get("sites", []):
					if Vector2(px - site[0], pz - site[2]).length_squared() < 25: nearby = true
				for row: Array in game.match_state.chests:
					if Vector2(px - row[1], pz - row[3]).length_squared() < GAP * GAP: nearby = true
				if nearby or not clear(game, at, shape): continue
				game.match_state.chests.append([game.match_state.chests.size(), snappedf(at.x, 0.001), snappedf(at.y, 0.001), snappedf(at.z, 0.001), 0])
				break
	game.pack.field.update(false)

static func clear(game: BattleRoyaleGame, at: Vector3, shape: BoxShape3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = at + Vector3.UP * (shape.size.y * 0.5 + 0.01)
	query.collision_mask = 1
	return game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
