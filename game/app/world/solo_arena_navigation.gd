class_name SoloArenaNavigation
extends RefCounted
## Small visibility graph through the authored cover corridors, with no navmesh.

var graph := AStar3D.new()
var body: CharacterBody3D

func build(actor: CharacterBody3D, center: Vector3) -> void:
	body = actor
	var id: int = 0
	for x in [-18.5, -14.0, -8.5, -3.0, 3.0, 8.5, 14.0, 18.5]:
		for z in [-14.0, -7.5, 7.5, 14.0]:
			graph.add_point(id, center + Vector3(x, 0.15, z))
			id += 1
	for a in graph.get_point_ids():
		for b in graph.get_point_ids():
			if b <= a: continue
			if clear(graph.get_point_position(a), graph.get_point_position(b)):
				graph.connect_points(a, b)

func next(at: Vector3, destination: Vector3) -> Vector3:
	if clear(at, destination): return destination
	var start := _nearest_visible(at)
	var end := _nearest_visible(destination)
	if start < 0 or end < 0: return at
	var path := graph.get_point_path(start, end)
	var waypoint := graph.get_point_position(start)
	for point in path:
		if not clear(at, point): break
		waypoint = point
	return waypoint

func _nearest_visible(at: Vector3) -> int:
	var nearest: int = -1
	var best: float = INF
	for id in graph.get_point_ids():
		var point := graph.get_point_position(id)
		var distance := point.distance_squared_to(at)
		if distance < best and clear(at, point):
			best = distance
			nearest = id
	return nearest

func clear(at: Vector3, destination: Vector3) -> bool:
	var offset := destination - at
	offset.y = 0.0
	var side := offset.normalized().cross(Vector3.UP) * 0.5
	for margin in [-1.0, 0.0, 1.0]:
		var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.85 + side * margin, destination + Vector3.UP * 0.85 + side * margin, 1)
		if not body.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	return true
