class_name FrostTerrain
extends RefCounted
## High northern snowfields with a sheltered route out of the sea.

const NORTH_START: float = OceanTerrain.NORTH_END
const NORTH_END: float = -368.0
const HALF_WIDTH: float = OceanTerrain.HALF_WIDTH

static func height_at(x: float, z: float, ocean: OceanWorld) -> float:
	var snow := 2.5 + sin(x * 0.12 + z * 0.09) * 1.5 + cos(x * 0.2 - z * 0.16) * 0.75
	snow += 4.4 * exp(-Vector2(x - 28, z + 159).length_squared() / 260.0)
	snow = lerpf(snow, 1.15, 1.0 - smoothstep(2.0, 5.2, trail_distance(x, z)))
	var blend := smoothstep(0.0, 1.0, clampf((NORTH_START - z) / 22.0, 0.0, 1.0))
	return lerpf(ocean.point(x, maxf(z, NORTH_START)).y, snow, blend)

static func trail_distance(x: float, z: float) -> float:
	var pass_distance := absf(x - sin((z - NORTH_START) * 0.12) * 5.0)
	var lake_loop := absf(Vector2(x - 22.0, z + 149.0).length() - 13.0)
	return minf(pass_distance, lake_loop)

static func build(parent: Node3D, ocean: OceanWorld) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(NORTH_END), int(NORTH_START) + 1):
		for x in range(-int(HALF_WIDTH), int(HALF_WIDTH)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				var shade := (sin(px * 0.37) + cos(pz * 0.28) + 2.0) * 0.25
				var color := Color("c4e3e7").lerp(Color("f3fbfa"), shade)
				color = color.lerp(Color("9bd1df"), 1.0 - smoothstep(1.0, 2.8, trail_distance(px, pz)))
				surface.set_color(color)
				surface.add_vertex(Vector3(px, height_at(px, pz, ocean), pz))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "FrostGround"
	ground.mesh = surface.commit()
	var material := MeadowGeometry.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
