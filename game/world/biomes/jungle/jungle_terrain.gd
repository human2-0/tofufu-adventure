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
	# A shallow, walkable basin beneath the water, with a continuous dry bank.
	var basin := Vector2((x + 40.0) / 14.0, (z - 314.0) / 10.0).length()
	hills = lerpf(1.30, hills, smoothstep(0.75, 1.10, basin))
	hills += WorldContours.rim(x, z, HALF_WIDTH, SOUTH_START, SOUTH_END, desert.farm.noise.seed, true)
	return JungleCoast.height_at(x, z, lerpf(desert.point(x, minf(z, SOUTH_START)).y, hills, blend), desert.farm.noise.seed)

static func trail_distance(x: float, z: float) -> float:
	var main := absf(x - (sin((z - SOUTH_START) * 0.15) * 3.0))
	var loop := absf(Vector2(x * 0.9, z - 143).length() - 15.0)
	return minf(main, loop)

static func build(parent: Node3D, desert: DesertWorld) -> void:
	var grid := TerrainGrid.new(Rect2i(-int(HALF_WIDTH), int(SOUTH_START), int(HALF_WIDTH + JungleCoast.SEA_EDGE), int(SOUTH_END - SOUTH_START)), func(x: float, z: float) -> float: return height_at(x, z, desert), desert.farm.noise.seed)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(SOUTH_START), int(SOUTH_END)):
		for x in range(-int(HALF_WIDTH), int(JungleCoast.SEA_EDGE)):
			for corner in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = x + corner.x
				var pz: float = z + corner.y
				var color := grid.color(px, pz)
				color = JungleCoast.color_at(Vector2(px, pz), grid.height(px, pz), color)
				color = color.lerp(Color("bdac72"), 1.0 - smoothstep(1.0, 2.3, trail_distance(px, pz)))
				surface.set_color(color.srgb_to_linear())
				surface.add_vertex(Vector3(px, grid.height(px, pz), pz))
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "JungleGround"
	ground.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/jungle/jungle_ground.gdshader")
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	TerrainSupport.mark_permanent(ground)
	TerrainChunks.split_visual(ground)
