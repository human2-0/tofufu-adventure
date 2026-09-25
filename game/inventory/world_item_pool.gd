class_name WorldItemPool
extends Node3D
## Shared bounded collection of drops. App composition decides who receives items.

const LIMIT: int = 128
const REACH: float = 2.4
var drops: Dictionary[int, WorldItemDrop] = {}
var next_id: int = 1
var authoritative: bool = true
var build_visual: Callable

func spawn(item_id: String, count: int, origin: Vector3, direction: Vector2, reserve: float = 100.0, contents: Array = []) -> WorldItemDrop:
	if drops.size() >= LIMIT: return null
	var start := origin + Vector3.UP * 0.6
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = WorldItemDrop.RADIUS
	query.shape = shape
	query.collision_mask = 1
	query.transform = Transform3D(Basis.IDENTITY, start)
	var space := get_world_3d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty(): return null
	var forward := Vector3(direction.x, 0, direction.y).normalized()
	query.motion = forward * 0.9
	var sweep := space.cast_motion(query)
	var at := start + query.motion * maxf(0, sweep[0] - 0.04)
	var drop := _create(next_id, item_id, count, reserve, at, contents)
	next_id += 1
	drop.velocity = forward * 1.3
	return drop

func _create(id: int, item_id: String, count: int, reserve: float, at: Vector3, contents: Array = []) -> WorldItemDrop:
	var drop := WorldItemDrop.new()
	drop.drop_id = id
	drop.item_id = item_id
	drop.count = count
	drop.reserve = reserve
	drop.contents = contents.duplicate(true)
	drop.authoritative = authoritative
	add_child(drop)
	drop.global_position = at
	drop.last_safe = at
	drops[id] = drop
	if build_visual.is_valid(): build_visual.call(drop)
	return drop

func reachable(drop: WorldItemDrop, origin: Vector3) -> bool:
	if not is_instance_valid(drop) or drop.is_queued_for_deletion(): return false
	if origin.distance_to(drop.global_position) > REACH: return false
	var ray := PhysicsRayQueryParameters3D.create(origin + Vector3.UP * 0.6, drop.global_position, 1)
	ray.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func focused(origin: Vector3, aim: Vector2, point: Vector3 = Vector3.INF) -> int:
	var best: int = 0
	var score: float = INF
	for id: int in drops:
		var drop := drops[id]
		if not reachable(drop, origin): continue
		var offset := Vector2(drop.global_position.x - origin.x, drop.global_position.z - origin.z)
		var alignment := aim.normalized().dot(offset.normalized())
		if offset.length() > 0.65 and alignment < 0.45: continue
		var candidate := (1.0 - alignment) * 2.0 + offset.length() * 0.3
		if point.is_finite(): candidate += Vector2(drop.global_position.x - point.x, drop.global_position.z - point.z).length()
		if candidate < score or (is_equal_approx(candidate, score) and id < best):
			score = candidate
			best = id
	return best

func remove(id: int) -> void:
	if not drops.has(id): return
	var drop := drops[id]
	drops.erase(id) # Remove synchronously: a second actor cannot collect it this tick.
	drop.queue_free()

func capture() -> Array:
	var rows: Array = []
	for drop: WorldItemDrop in drops.values(): rows.append(drop.capture())
	return rows

func restore(rows: Array) -> void:
	var live: Array[int] = []
	for row: Array in rows:
		var id := int(row[0])
		live.append(id)
		var at := Vector3(row[4], row[5], row[6])
		if drops.has(id) and drops[id].item_id != row[1]: remove(id)
		if not drops.has(id): _create(id, row[1], int(row[2]), float(row[3]), at, row[7] if row.size() > 7 else [])
		var drop := drops[id]
		drop.count = int(row[2])
		drop.reserve = float(row[3])
		drop.contents = (row[7] if row.size() > 7 else []).duplicate(true)
		drop.global_position = at
		drop.last_safe = at
		next_id = maxi(next_id, id + 1)
	for id: int in drops.keys():
		if id not in live: remove(id)
