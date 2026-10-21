class_name GigalopolisFurnishings
extends RefCounted
## Sparse furnishings keep a clear central route from every doorway.

static func build(room: Node3D, style: String) -> void:
	var size: Vector3 = room.get_meta("city_size")
	var floor_y: float = room.get_meta("city_floor")
	GigalopolisGeometry.box(room, Vector3(0, floor_y + 0.015, 1), Vector3(minf(size.x - 2, 5), 0.025, minf(size.z - 4, 6)), "rug")
	if style == "home":
		var bed := Vector3(-size.x / 2 + 1.5, floor_y, -size.z / 2 + 3)
		GigalopolisGeometry.box(room, bed + Vector3.UP * 0.22, Vector3(2, 0.44, 3), "wood", true)
		GigalopolisGeometry.box(room, bed + Vector3.UP * 0.48, Vector3(1.9, 0.12, 2.8), "canvas")
		GigalopolisGeometry.box(room, bed + Vector3(0, 0.61, -0.9), Vector3(1.5, 0.18, 0.6), "plaster")
		_table(room, Vector3(size.x / 2 - 1.3, floor_y, 0), Vector2(1.5, 2))
	else:
		for side: float in [-1, 1]:
			_table(room, Vector3(side * (size.x / 2 - 1.7), floor_y, 0), Vector2(2, minf(5, size.z / 3)))
		if style == "work":
			for side: float in [-1, 1]:
				GigalopolisGeometry.box(room, Vector3(side * (size.x / 2 - 2), floor_y + 0.7, -size.z / 2 + 2), Vector3(2, 1.4, 2), "wood", true)
	# A shallow cupboard sits against the rear wall without filling the chest aisle.
	GigalopolisGeometry.box(room, Vector3(size.x / 2 - 1.2, floor_y + 1.1, -size.z / 2 + 0.8), Vector3(1.5, 2.2, 0.7), "wood", true)
	for y: float in [0.6, 1.4, 2.1]:
		GigalopolisGeometry.box(room, Vector3(size.x / 2 - 1.2, floor_y + y, -size.z / 2 + 1.18), Vector3(1.55, 0.1, 0.18), "brass")

static func _table(room: Node3D, at: Vector3, size: Vector2) -> void:
	GigalopolisGeometry.box(room, at + Vector3.UP * 0.85, Vector3(size.x, 0.18, size.y), "wood", true)
	for x: float in [-1, 1]:
		for z: float in [-1, 1]:
			GigalopolisGeometry.box(room, at + Vector3(x * (size.x / 2 - 0.15), 0.4, z * (size.y / 2 - 0.15)), Vector3(0.16, 0.8, 0.16), "wood", true)
	GigalopolisGeometry.box(room, at + Vector3.UP * 0.97, Vector3(size.x * 0.65, 0.04, size.y * 0.55), "canvas")
