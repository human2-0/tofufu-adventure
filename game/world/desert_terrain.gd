class_name DesertTerrain
extends RefCounted
## Broad southern sand sea. Its winding open route keeps the meadow and jungle legible.

const SOUTH_START: float = 84.0
const SOUTH_END: float = 216.0
const HALF_WIDTH: float = 80.0

static func height_at(x: float, z: float, farm: FarmTerrain) -> float:
	var dune := 1.0 + sin(x * 0.13 + z * 0.08) * 1.45
	dune += cos(x * 0.22 - z * 0.11) * 0.75
	dune += 2.0 * exp(-Vector2(x + 22, z - 83).length_squared() / 180.0)
	var trail_flatten := 1.0 - smoothstep(2.0, 5.2, trail_distance(x, z))
	dune = lerpf(dune, 0.72, trail_flatten)
	var blend := smoothstep(SOUTH_START, SOUTH_START + 20.0, z)
	var height := lerpf(farm.height_at(x, minf(z, SOUTH_START)), dune, blend)
	var carved := RiverCourse.carve(x, z, height)
	return lerpf(farm.height_at(x, SOUTH_START), carved, smoothstep(SOUTH_START, SOUTH_START + 2.0, z))

static func trail_distance(x: float, z: float) -> float:
	var caravan := absf(x - sin((z - SOUTH_START) * 0.14) * 4.0)
	var oasis_branch := Vector2(maxf(0.0, absf(x + 19.0) - 19.0), z - 160.0).length()
	var oasis_ring := absf(Vector2((x + 38.0) * 0.85, z - 148.0).length() - 12.0)
	return minf(caravan, minf(oasis_branch, oasis_ring))

static func build(parent: Node3D, farm: FarmTerrain) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(SOUTH_START), int(SOUTH_END) + 1):
		for x in range(-int(HALF_WIDTH), int(HALF_WIDTH)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				var shade := (sin(px * 0.38) + cos(pz * 0.31) + 2.0) * 0.25
				var color := Color("c9924e").lerp(Color("f1cf84"), shade)
				color = color.lerp(Color("e6ba70"), 1.0 - smoothstep(1.2, 3.2, trail_distance(px, pz)))
				var bank := RiverCourse.bank_distance(px, pz)
				color = color.lerp(Color("779466"), 1.0 - smoothstep(0.2, 3.5, bank))
				color = color.lerp(Color("9f9c70"), 1.0 - smoothstep(-1.0, 0.4, bank))
				surface.set_color(color)
				surface.add_vertex(Vector3(px, height_at(px, pz, farm), pz))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "DesertGround"
	ground.mesh = surface.commit()
	var material := MeadowGeometry.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
