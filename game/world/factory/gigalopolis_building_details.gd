class_name GigalopolisBuildingDetails
extends RefCounted
## Consistent foundations, recessed glazing, doors and guarded public terraces.

static func foundation(parent: Node3D, size: Vector2) -> void:
	var bottom := -0.4
	for offset: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var at := Vector2(parent.position.x, parent.position.z) + offset * size * 0.5
		bottom = minf(bottom, GigalopolisTerrain.point(at).y - parent.position.y - 0.3)
	var height := 0.5 - bottom
	GigalopolisGeometry.box(parent, Vector3(0, bottom + height * 0.5, 0), Vector3(size.x, height, size.y), "stone", true)

static func windows(parent: Node3D, at: Vector3, width: float, height: float, normal: Vector3) -> void:
	var size := Vector3(width, height, 0.18) if absf(normal.z) > 0 else Vector3(0.18, height, width)
	GigalopolisGeometry.box(parent, at, size + Vector3(0.2, 0.2, 0.2), "metal").set_meta("city_wall", true)
	GigalopolisGeometry.box(parent, at + normal * 0.15, size, "glass").set_meta("city_wall", true)

static func door(parent: Node3D, at: Vector3, width: float = 3.0) -> void:
	var floor_y: float = parent.get_meta("city_floor", 0.0)
	for side: float in [-1, 1]:
		GigalopolisGeometry.box(parent, at + Vector3(side * (width / 2 + 0.1), floor_y + 1.7, 0), Vector3(0.2, 3.4, 0.28), "metal").set_meta("city_wall", true)
	GigalopolisGeometry.box(parent, at + Vector3(0, floor_y + 3.4, 0), Vector3(width + 0.4, 0.2, 0.3), "brass").set_meta("city_wall", true)
	GigalopolisGeometry.box(parent, at + Vector3(0, floor_y + 3.7, 0.7), Vector3(width + 1.2, 0.2, 1.7), "canvas").set_meta("city_wall", true)

static func parapet(parent: Node3D, center: Vector3, size: Vector2, opening: Vector2) -> void:
	for side: float in [-1, 1]:
		GigalopolisGeometry.box(parent, center + Vector3(0, 0.6, side * size.y * 0.5), Vector3(size.x, 1.2, 0.18), "metal", true)
	GigalopolisGeometry.box(parent, center + Vector3(-size.x * 0.5, 0.6, 0), Vector3(0.18, 1.2, size.y), "metal", true)
	for interval: Vector2 in [Vector2(-size.y * 0.5, opening.x), Vector2(opening.y, size.y * 0.5)]:
		if interval.y <= interval.x: continue
		GigalopolisGeometry.box(parent, center + Vector3(size.x * 0.5, 0.6, (interval.x + interval.y) * 0.5), Vector3(0.18, 1.2, interval.y - interval.x), "metal", true)

static func stair(parent: Node3D, start: Vector2, finish: Vector2, top: float) -> void:
	var world_start := Vector2(parent.position.x, parent.position.z) + start
	var y := GigalopolisTerrain.point(world_start).y - parent.position.y
	var bottom := Vector3(start.x, y, start.y)
	var end := Vector3(finish.x, top, finish.y)
	GigalopolisGeometry.stair(parent, bottom, end, 3.6)
	for weight: float in [0.25, 0.5, 0.75]:
		var at := bottom.lerp(end, weight)
		var ground := GigalopolisTerrain.point(Vector2(parent.position.x + at.x, parent.position.z + at.z)).y - parent.position.y
		var height := at.y - ground - 0.3
		if height > 0.4:
			GigalopolisGeometry.box(parent, Vector3(at.x, ground + height * 0.5, at.z), Vector3(0.5, height, 0.5), "metal", true)

static func landing(parent: Node3D, center: Vector3, width: float) -> void:
	GigalopolisGeometry.box(parent, center - Vector3.UP * 0.15, Vector3(width, 0.3, 4), "paving", true)
	GigalopolisGeometry.box(parent, center + Vector3(0, 0.6, -2), Vector3(width, 1.2, 0.18), "metal", true)
	GigalopolisGeometry.box(parent, center + Vector3(width * 0.5, 0.6, -1), Vector3(0.18, 1.2, 2), "metal", true)
