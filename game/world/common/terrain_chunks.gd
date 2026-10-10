class_name TerrainChunks
extends RefCounted
## Exact visual triangles in independently culled tiles; original collision stays intact.

const SIZE: float = 24.0

static func split_visual(ground: MeshInstance3D, force: bool = false, tile_size: float = SIZE) -> void:
	if not force and DisplayServer.get_name() == "headless": return
	var source := ground.mesh
	var tiles: Dictionary[Vector2i, SurfaceTool] = {}
	var arrays := source.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var count := indices.size() if not indices.is_empty() else vertices.size()
	for triangle in range(0, count, 3):
		var first := indices[triangle] if not indices.is_empty() else triangle
		var at := vertices[first]
		var key := Vector2i(floori(at.x / tile_size), floori(at.z / tile_size))
		if not tiles.has(key):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			tiles[key] = surface
		for corner in 3:
			var index := indices[triangle + corner] if not indices.is_empty() else triangle + corner
			_append(tiles[key], arrays, index)
	for key: Vector2i in tiles:
		tiles[key].index()
		var tile := MeshInstance3D.new()
		tile.name = "Tile_%d_%d" % [key.x, key.y]
		tile.mesh = tiles[key].commit()
		tile.material_override = ground.material_override
		tile.cast_shadow = ground.cast_shadow
		tile.extra_cull_margin = maxf(ground.extra_cull_margin, 0.6)
		ground.add_child(tile)
	# Removing the original visual does not alter its StaticBody3D children.
	ground.mesh = null

static func _append(surface: SurfaceTool, arrays: Array, index: int) -> void:
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if not normals.is_empty(): surface.set_normal(normals[index])
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	if not colors.is_empty(): surface.set_color(colors[index])
	if arrays[Mesh.ARRAY_TEX_UV] != null:
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		if not uvs.is_empty(): surface.set_uv(uvs[index])
	surface.add_vertex(arrays[Mesh.ARRAY_VERTEX][index])
