class_name OceanTerrain
extends RefCounted
## A wide northern seabed with a gently descending, collision-backed exploration route.

const NORTH_START: float = -84.0
const NORTH_END: float = -220.0
const HALF_WIDTH: float = 140.0
const WATER_LEVEL: float = 1.8

static func height_at(x: float, z: float, farm: FarmTerrain) -> float:
	var seabed := -4.8 + sin(x * 0.11 - z * 0.14) * 1.15 + cos(x * 0.19 + z * 0.07) * 0.7
	seabed += 1.5 * exp(-Vector2(x + 28, z + 82).length_squared() / 230.0)
	seabed = lerpf(seabed, -3.85, 1.0 - smoothstep(2.0, 5.2, trail_distance(x, z)))
	var inland := farm.height_at(x, NORTH_START)
	var distance := NORTH_START - z
	var coast := distance - WorldContours.coast(x, farm.noise.seed)
	var beach := lerpf(2.85, 2.2, smoothstep(7.0, 16.0, coast))
	beach = lerpf(beach, seabed, smoothstep(16.0, 42.0, coast))
	var northern_coast := z - NORTH_END - WorldContours.coast(x, farm.noise.seed + 33) * 0.7 * smoothstep(0.0, 12.0, z - NORTH_END)
	beach = lerpf(beach, 2.5, 1.0 - smoothstep(0.0, 25.0, northern_coast))
	beach = OceanIslands.height_at(x, z, beach, farm.noise.seed)
	var rim := WorldContours.rim(x, z, HALF_WIDTH, NORTH_START, NORTH_END, farm.noise.seed)
	beach += rim * smoothstep(3.0, 20.0, distance)
	return lerpf(inland, beach, smoothstep(0.0, 8.0, distance))

static func trail_distance(x: float, z: float) -> float:
	var current := absf(x - sin((z - NORTH_START) * 0.14) * 5.0)
	var reef_loop := absf(Vector2(x + 26.0, z + 80.0).length() - 12.0)
	return minf(current, reef_loop)

static func build(parent: Node3D, farm: FarmTerrain) -> TerrainGrid:
	var grid := TerrainGrid.new(Rect2i(-int(HALF_WIDTH), int(NORTH_END), int(HALF_WIDTH * 2), int(NORTH_START - NORTH_END)), func(x: float, z: float) -> float: return height_at(x, z, farm), farm.noise.seed)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(NORTH_END), int(NORTH_START)):
		for x in range(-int(HALF_WIDTH), int(HALF_WIDTH)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				var color := grid.color(px, pz)
				surface.set_color(color.srgb_to_linear())
				surface.add_vertex(Vector3(px, grid.height(px, pz), pz))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "OceanSeabed"
	ground.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/ocean/ocean_sand.gdshader")
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	TerrainSupport.mark_permanent(ground)
	TerrainChunks.split_visual(ground)
	return grid
