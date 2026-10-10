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
	_outer_water(surface)
	surface.generate_normals()
	surface.index()
	mesh = surface.commit()
	material_override = OceanMaterial.create(Vector2(128, -64), Color("328e9d"), Color("07344e"))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = mesh.get_aabb().grow(0.6)
	TerrainChunks.split_visual(self, false, 64.0)

func _outer_water(surface: SurfaceTool) -> void:
	# Scenery extends beyond traversal bounds so the sea reaches the horizon.
	for area: Rect2i in [Rect2i(706, 188, 366, 744), Rect2i(82, 592, 624, 340), Rect2i(82, 56, 990, 132), Rect2i(-500, 340, 582, 592)]:
		for z in range(area.position.y, area.end.y, 8):
			for x in range(area.position.x, area.end.x, 8):
				var width := mini(8, area.end.x - x)
				var depth := mini(8, area.end.y - z)
				for offset: Vector2 in [Vector2.ZERO, Vector2(width, 0), Vector2(0, depth), Vector2(width, 0), Vector2(width, depth), Vector2(0, depth)]:
					surface.set_color(Color(56.0 / 128.0, 0, 0))
					surface.add_vertex(Vector3(x + offset.x, VolcanicTerrain.WATER_LEVEL - 0.18, z + offset.y))
