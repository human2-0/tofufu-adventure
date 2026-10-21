class_name GigalopolisInterior
extends RefCounted
## Real room shells, level floors and graded entrances; roofs retain their collision.

static func shell(parent: Node3D, at: Vector3, size: Vector3, kind: String = "stone", doorway: float = 3.0) -> Node3D:
	var room := Node3D.new()
	room.name = "CityRoom"
	room.position = at
	parent.add_child(room)
	var base := room.global_position
	var floor_y := 0.15
	var bottom := -0.3
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var sample := Vector2(base.x, base.z) + corner * Vector2(size.x, size.z) * 0.5
		var ground := GigalopolisTerrain.point(sample).y - base.y
		floor_y = maxf(floor_y, ground + 0.15)
		bottom = minf(bottom, ground - 0.3)
	GigalopolisGeometry.box(room, Vector3(0, (bottom + floor_y - 0.1) / 2, 0), Vector3(size.x, floor_y - 0.1 - bottom, size.z), "stone", true)
	GigalopolisGeometry.box(room, Vector3(0, floor_y - 0.05, 0), Vector3(size.x - 0.12, 0.1, size.z - 0.12), "floor", true)
	room.set_meta("city_size", size)
	room.set_meta("city_floor", floor_y)
	var height := size.y - floor_y
	var center_y := floor_y + height / 2
	_wall(room, Vector3(0, center_y, -size.z / 2), Vector3(size.x, height, 0.35), kind)
	for side: float in [-1, 1]:
		_wall(room, Vector3(side * size.x / 2, center_y, 0), Vector3(0.35, height, size.z), kind)
		var width := (size.x - doorway) / 2
		_wall(room, Vector3(side * (doorway + width) / 2, center_y, size.z / 2), Vector3(width, height, 0.35), kind)
	var lintel := maxf(0.15, height - 3.4)
	_wall(room, Vector3(0, size.y - lintel / 2, size.z / 2), Vector3(doorway, lintel, 0.35), kind)
	_entry(room, size.z / 2, floor_y, doorway)
	var rooms: Array = parent.get_meta("city_rooms", [])
	rooms.append(room)
	parent.set_meta("city_rooms", rooms)
	return room

static func _wall(room: Node3D, at: Vector3, size: Vector3, kind: String) -> void:
	GigalopolisGeometry.box(room, at, size, kind, true).set_meta("city_wall", true)

static func _entry(room: Node3D, front: float, floor_y: float, width: float) -> void:
	var at := room.global_position + Vector3(0, 0, front + 3)
	var ground := GigalopolisTerrain.point(Vector2(at.x, at.z)).y - room.global_position.y
	var start := Vector3(0, ground + 0.02, front + 3)
	var finish := Vector3(0, floor_y, front + 0.1)
	var delta := finish - start
	var tilt := Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, -atan2(delta.y, 2.9))
	var ramp := GigalopolisGeometry.box(room, (start + finish) / 2 - tilt * Vector3.UP * 0.08, Vector3(width, 0.16, delta.length()), "paving", true)
	ramp.basis = tilt
	room.set_meta("city_entry", start)

static func finish(room: Node3D, style: String) -> void:
	GigalopolisFurnishings.build(room, style)
	var size: Vector3 = room.get_meta("city_size")
	var walls: Array[MeshInstance3D] = []
	var roofs: Array[MeshInstance3D] = []
	_collect_views(room, room, size.y, roofs, walls)
	for view in roofs + walls: SolidOcclusion.box(view)
	var roof_height := size.y
	for view in roofs:
		for corner in 8:
			roof_height = maxf(roof_height, room.to_local(view.to_global(view.mesh.get_aabb().get_endpoint(corner))).y)
	room.set_meta("city_roof_height", roof_height)
	room.set_meta("interior_roofs", roofs)
	room.set_meta("interior_walls", walls)

static func _collect_views(parent: Node3D, room: Node3D, top: float, roofs: Array[MeshInstance3D], walls: Array[MeshInstance3D]) -> void:
	# Traverse only the geometry owned by this shell, before decoration batching.
	for child in parent.get_children():
		if child is MeshInstance3D:
			var local := room.to_local(child.global_position)
			if local.y >= top - 0.35: roofs.append(child)
			elif child.get_meta("city_wall", false): walls.append(child)
			else: continue
			child.set_meta("cutaway_ornament", true)
		elif child is Node3D and not child is CollisionObject3D:
			_collect_views(child, room, top, roofs, walls)
