@tool
class_name TreeLeafMesh
extends RefCounted
## Folded pointed leaves form porous, asymmetric sprays instead of solid crowns.

static func add_spray(surface: SurfaceTool, rng: RandomNumberGenerator, center: Vector3, size: Vector3, orchard: bool) -> void:
	var palette: Array[Color] = [Color("35654b"), Color("4b8557"), Color("6b9c62"), Color("86ad6b")]
	if orchard: palette = [Color("365a2e"), Color("4c7e35"), Color("6c973e"), Color("89ac4b")]
	for index in 85:
		var offset := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		while offset.length_squared() > 1.0:
			offset = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		var at := center + offset * size
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.9), rng.randf_range(-1, 1)).normalized()
		var side := direction.cross(Vector3.UP).normalized()
		var normal := side.cross(direction).normalized()
		var length := rng.randf_range(0.22, 0.37)
		var width := length * rng.randf_range(0.30, 0.45)
		var base := at - direction * length * 0.45
		var tip := at + direction * length * 0.65
		var ridge := at + normal * width * 0.22
		var color := palette[rng.randi_range(0, palette.size() - 1)]
		_triangle(surface, base, ridge, at + side * width, color)
		_triangle(surface, at + side * width, ridge, tip, color)
		_triangle(surface, base, at - side * width, ridge, color.darkened(0.12))
		_triangle(surface, at - side * width, tip, ridge, color.darkened(0.12))

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	surface.set_color(color)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

static func distant_indices(arrays: Array) -> PackedInt32Array:
	# Flatten each folded four-triangle leaf, preserving its entire silhouette.
	var original: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var indices := PackedInt32Array()
	for start in range(0, original.size(), 12):
		for corner in [0, 2, 5, 6, 10, 7]: indices.append(original[start + corner])
	return indices
