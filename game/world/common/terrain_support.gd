class_name TerrainSupport
extends RefCounted
## Explicit physical contract for terrain built once and never deformed in place.

static func mark_permanent(ground: MeshInstance3D) -> void:
	for child in ground.get_children():
		if child is StaticBody3D: child.set_meta("permanent_terrain", true)
