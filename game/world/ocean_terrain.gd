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
	var blend := smoothstep(0.0, 1.0, clampf((NORTH_START - z) / 20.0, 0.0, 1.0))
	return lerpf(farm.height_at(clampf(x, -42.0, 42.0), maxf(z, NORTH_START)), seabed, blend)

static func trail_distance(x: float, z: float) -> float:
	var current := absf(x - sin((z - NORTH_START) * 0.14) * 5.0)
	var reef_loop := absf(Vector2(x + 26.0, z + 80.0).length() - 12.0)
	return minf(current, reef_loop)

static func build(parent: Node3D, farm: FarmTerrain) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(NORTH_END), int(NORTH_START) + 1):
		for x in range(-int(HALF_WIDTH), int(HALF_WIDTH)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				var shade := (sin(px * 0.43) + cos(pz * 0.36) + 2.0) * 0.25
				var color := Color("245c6c").lerp(Color("4a8a85"), shade)
				color = color.lerp(Color("78a699"), 1.0 - smoothstep(1.2, 3.1, trail_distance(px, pz)))
				surface.set_color(color)
				surface.add_vertex(Vector3(px, height_at(px, pz, farm), pz))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "OceanSeabed"
	ground.mesh = surface.commit()
	var material := MeadowGeometry.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
