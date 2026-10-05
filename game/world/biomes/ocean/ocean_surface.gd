class_name OceanSurface
extends MeshInstance3D
## Subdivided swells with terrain-derived shore clipping and sky reflections.

func build(farm: FarmTerrain, cached_grid: TerrainGrid = null) -> void:
	name = "AquaDepthsSurface"
	var grid := cached_grid
	if grid == null: grid = TerrainGrid.new(Rect2i(-140, -220, 280, 124), func(x: float, z: float) -> float: return OceanTerrain.height_at(x, z, farm), farm.noise.seed)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(OceanTerrain.NORTH_END), int(OceanTerrain.NORTH_START - 12)):
		for x in range(-int(OceanTerrain.HALF_WIDTH), int(OceanTerrain.HALF_WIDTH)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				surface.set_color(Color((grid.height(px, pz) + 8.0) / 16.0, 0, 0))
				surface.set_uv(Vector2(px, pz))
				surface.add_vertex(Vector3(px, OceanTerrain.WATER_LEVEL, pz))
	surface.generate_normals()
	mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/ocean/ocean_water.gdshader")
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Water is presentation; collision remains on the continuous sandy floor.
	custom_aabb = mesh.get_aabb().grow(0.5)
