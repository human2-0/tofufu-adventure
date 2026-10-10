class_name JungleCoast
extends RefCounted
## East beach slopes into the same Y=-8 seabed as the offshore ocean channel.

const SEA_EDGE: float = 82.0
const WATER_LEVEL: float = 1.2

static func shore_x(z: float, seed: int) -> float:
	return 64.0 + WorldContours.noise(Vector2(z / 28.0, 4.2), seed + 816) * 3.0

static func height_at(x: float, z: float, inland: float, seed: int) -> float:
	var shore := shore_x(z, seed)
	var beach := lerpf(2.4, -8.0, smoothstep(shore, SEA_EDGE, x))
	var entry_blend := smoothstep(JungleTerrain.SOUTH_START, JungleTerrain.SOUTH_START + 14, z)
	var blend := smoothstep(52.0, shore - 3.0, x) * entry_blend
	# Close the edge even where the northern desert ridge meets the beach.
	blend = maxf(blend, smoothstep(76.0, SEA_EDGE, x))
	return lerpf(inland, beach, blend)

static func color_at(at: Vector2, height: float, inland: Color) -> Color:
	if at.x < 53: return inland
	var sand := Color("dcc695").lerp(Color("b5a38c"), smoothstep(WATER_LEVEL, -7.0, height))
	return inland.lerp(sand, smoothstep(53.0, 64.0, at.x))

static func build_water(parent: Node3D, desert: DesertWorld) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(int(JungleTerrain.SOUTH_START), int(JungleTerrain.SOUTH_END), 2):
		for x in range(54, int(SEA_EDGE), 2):
			for offset: Vector2 in [Vector2.ZERO, Vector2(2, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]:
				var at := Vector2(x, z) + offset
				var bed := JungleTerrain.height_at(at.x, at.y, desert)
				surface.set_color(Color((bed + 64.0) / 128.0, 0, 0))
				surface.add_vertex(Vector3(at.x, WATER_LEVEL - 0.18, at.y))
	surface.generate_normals()
	surface.index()
	var water := MeshInstance3D.new()
	water.name = "JadewildEasternSea"
	water.mesh = surface.commit()
	water.material_override = OceanMaterial.create(Vector2(128, -64), Color("328e9d"), Color("07344e"))
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.custom_aabb = water.mesh.get_aabb().grow(0.6)
	parent.add_child(water)
	TerrainChunks.split_visual(water, false, 64.0)

static func is_water(at: Vector3, desert: DesertWorld) -> bool:
	return at.x >= 54 and at.x <= SEA_EDGE and at.z >= JungleTerrain.SOUTH_START and at.z <= JungleTerrain.SOUTH_END and at.y < WATER_LEVEL and JungleTerrain.height_at(at.x, at.z, desert) < WATER_LEVEL
