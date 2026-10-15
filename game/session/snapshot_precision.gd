class_name SnapshotPrecision
extends RefCounted
## Millimetre display coordinates suppress submillimetre physics jitter on wire.
## Authority, damage, resources, progression and saved captures remain exact.

static func presentation(snapshot: Dictionary) -> Dictionary:
	var result := snapshot.duplicate()
	var actors: Dictionary = snapshot.actors.duplicate()
	for key: String in actors:
		var actor: Dictionary = actors[key].duplicate()
		actor.position = _vector(actor.position)
		actor.velocity = _vector(actor.velocity)
		actors[key] = actor
	result.actors = actors
	if snapshot.has("world"):
		var world: Dictionary = snapshot.world.duplicate()
		world.mobs = _rows(world.mobs, 0, 6)
		world.pickups = _rows(world.pickups, 1, 3)
		if world.has("world_items"): world.world_items = _rows(world.world_items, 4, 3)
		result.world = world
	return result

static func _vector(values: Array) -> Array:
	var result := values.duplicate()
	for index in result.size(): result[index] = snappedf(float(result[index]), 0.001)
	return result

static func _rows(rows: Array, start: int, count: int) -> Array:
	var result: Array = []
	for source: Array in rows:
		var row := source.duplicate()
		for index in range(start, start + count): row[index] = snappedf(float(row[index]), 0.001)
		result.append(row)
	return result
