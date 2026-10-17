class_name VolcanicOcean
extends MeshInstance3D
## Terrain-coloured coastal swells without framebuffer copies or reflection tracing.

func build(grid: VolcanicGroundGrid) -> void:
	name = "VolcanicOcean"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(VolcanicTerrain.BOUNDS.position.y), int(VolcanicTerrain.BOUNDS.end.y), 2):
		for x in range(int(VolcanicTerrain.BOUNDS.position.x), int(VolcanicTerrain.BOUNDS.end.x), 2):
			# Keep dry terrain out of the water mesh, including the raised beach road.
			var center_height := (grid.heights[grid.index(Vector2(x, z))] + grid.heights[grid.index(Vector2(x + 2, z + 2))]) * 0.5
			if center_height > VolcanicTerrain.WATER_LEVEL + 0.8: continue
			for offset in [Vector2.ZERO, Vector2(2, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]:
				var at: Vector2 = Vector2(x, z) + offset
				surface.set_color(Color((grid.heights[grid.index(at)] + 64.0) / 128.0, 0, 0))
				surface.add_vertex(Vector3(at.x, VolcanicTerrain.WATER_LEVEL - 0.18, at.y))
	surface.generate_normals()
	surface.index()
	mesh = surface.commit()
	material_override = OceanMaterial.create(Vector2(128, -64), Color("328e9d"), Color("07344e"))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = mesh.get_aabb().grow(0.6)
	TerrainChunks.split_visual(self, false, 64.0)
