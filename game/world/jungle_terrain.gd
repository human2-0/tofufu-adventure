class_name JungleTerrain
extends RefCounted
## Southern jungle; its entrance blends exactly into the desert crossing.

const SOUTH_START: float = DesertTerrain.SOUTH_END
const SOUTH_END: float = 340.0
const HALF_WIDTH: float = 80.0

static func height_at(x: float, z: float, desert: DesertWorld) -> float:
	var blend := smoothstep(SOUTH_START, SOUTH_START + 20.0, z)
	var hills := 1.8 + sin(x * 0.16) * 1.1 + cos(z * 0.18) * 0.9
	hills += 4.0 * exp(-Vector2(x + 19, z - 157).length_squared() / 110.0)
	var trail := trail_distance(x, z)
	hills = lerpf(1.2, hills, smoothstep(1.5, 4.0, trail))
	return lerpf(desert.point(x, minf(z, SOUTH_START)).y, hills, blend)

static func trail_distance(x: float, z: float) -> float:
	var main := absf(x - (sin((z - SOUTH_START) * 0.15) * 3.0))
	var loop := absf(Vector2(x * 0.9, z - 143).length() - 15.0)
	return minf(main, loop)

static func build(parent: Node3D, desert: DesertWorld) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(SOUTH_START), int(SOUTH_END)):
		for x in range(-int(HALF_WIDTH), int(HALF_WIDTH)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				var shade := (sin(px * 0.7) * cos(pz * 0.8) + 1) * 0.5
				var color := Color("376c50").lerp(Color("67934f"), shade)
				color = color.lerp(Color("bdac72"), 1.0 - smoothstep(1.0, 2.3, trail_distance(px, pz)))
				surface.set_color(color)
				surface.add_vertex(Vector3(px, height_at(px, pz, desert), pz))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "JungleGround"
	ground.mesh = surface.commit()
	var material := MeadowGeometry.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
