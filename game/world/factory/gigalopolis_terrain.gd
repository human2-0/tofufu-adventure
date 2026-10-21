class_name GigalopolisTerrain
extends RefCounted
## Shared east-west city floors, northern volcanic beach and legacy coastal ward.

const BOUNDS := Rect2(84, -44, 576, 232)
const COAST_BOUNDS := Rect2(82, 188, 624, 216)
const AVENUES: Array[float] = [260, 324, 388, 452, 516, 580, 636]
const SPINE: Array[Vector2] = [Vector2(166, 188), Vector2(176, 238), Vector2(192, 280), Vector2(208, 318), Vector2(208, 374)]
const BEACH_LINK: Array[Vector2] = [Vector2(208, 318), Vector2(245, 318)]

static func contains(at: Vector2) -> bool:
	return at.x >= BOUNDS.position.x and at.x <= BOUNDS.end.x and at.y >= BOUNDS.position.y and at.y < BOUNDS.end.y

static func distance(at: Vector2, route: Array[Vector2]) -> float:
	var nearest := INF
	for index in route.size() - 1:
		nearest = minf(nearest, at.distance_to(Geometry2D.get_closest_point_to_segment(at, route[index], route[index + 1])))
	return nearest

static func street_distance(at: Vector2) -> float:
	if at.y >= 188: return minf(distance(at, SPINE), distance(at, BEACH_LINK))
	if at.x > 240:
		var lane := minf(absf(at.y - 6), minf(absf(at.y - 110), absf(at.y - 158)))
		for avenue in AVENUES: lane = minf(lane, absf(at.x - avenue))
		return lane
	var main := absf(at.y - 6)
	var avenue := absf(at.x - 160) if at.y >= 6 else INF
	var east := absf(at.x - lerpf(184.0, 202.0, smoothstep(44.0, 68.0, at.y)))
	var cross := minf(absf(at.y - 68), minf(absf(at.y - 110), absf(at.y - 150))) if at.y > 56 else INF
	return minf(main, minf(avenue, minf(east, cross)))

static func raw_height(at: Vector2) -> float:
	var rise := smoothstep(56.0, 104.0, at.y)
	var inland := lerpf(3.0 * smoothstep(184.0, 212.0, at.x), 4.0, rise)
	inland += 3.0 * smoothstep(312.0, 336.0, at.x) + 3.0 * smoothstep(504.0, 528.0, at.x)
	# Grade the high eastern terraces down before the last avenue and beach.
	inland = lerpf(inland, 3.5, smoothstep(576.0, 604.0, at.x))
	inland = lerpf(inland, -8.0, smoothstep(640.0, 680.0, at.x))
	var west := (1.0 - smoothstep(84.0, 114.0, at.x)) * smoothstep(84.0, 116.0, at.y)
	return lerpf(inland, -8.0, west)

static func height_at(at: Vector2) -> float:
	var cell := (at / 2.0).floor() * 2.0
	var uv := (at - cell) / 2.0
	var a := raw_height(cell)
	var b := raw_height(cell + Vector2(2, 0))
	var c := raw_height(cell + Vector2(0, 2))
	if uv.x + uv.y <= 1: return a + (b - a) * uv.x + (c - a) * uv.y
	var d := raw_height(cell + Vector2(2, 2))
	return d + (c - d) * (1 - uv.x) + (b - d) * (1 - uv.y)

static func coastal_height(at: Vector2, original: float) -> float:
	if not COAST_BOUNDS.has_point(at): return original
	if at.x >= 270:
		var apron := lerpf(raw_height(Vector2(at.x, 188)), -8.0, smoothstep(188.0, 224.0, at.y))
		return maxf(original, apron)
	var width := lerpf(30.0, 22.0, smoothstep(250.0, 310.0, at.y))
	var radius := distance(at, SPINE)
	var shore := lerpf(3.6, -8.0, smoothstep(width, width + 18.0, radius))
	shore = maxf(shore, lerpf(2.2, -8.0, smoothstep(9.0, 24.0, distance(at, BEACH_LINK))))
	shore = lerpf(raw_height(Vector2(at.x, 188)), shore, smoothstep(188.0, 224.0, at.y))
	return maxf(original, shore)

static func point(at: Vector2, lift: float = 0.0) -> Vector3:
	var height := height_at(at) if at.y < 188 else VolcanicTerrain.height_at(at.x, at.y)
	return Vector3(at.x, height + lift, at.y)

static func is_water(at: Vector3) -> bool:
	# The original factory foundations sit below sea level inside a dry district.
	var coastal := at.x > 628 or (at.z > 84 and at.x < 118)
	return coastal and at.y < 1.2 and height_at(Vector2(at.x, at.z)) < 1.2

static func color_at(at: Vector2, height: float) -> Color:
	if height < 2.1 and (at.x > 628 or at.y > 84): return Color("d9c393")
	if street_distance(at) < 4.0: return Color("c5b897")
	return Color("81948a") if at.y < 56 else Color("b0ac91")

static func build(parent: Node3D) -> void:
	var surface := SurfaceTool.new()
	var water := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(-44, 188, 2):
		for x in range(int(BOUNDS.position.x), int(BOUNDS.end.x), 2):
			var coastal := is_water(Vector3(x + 1, 0, z + 1))
			for offset: Vector2 in [Vector2.ZERO, Vector2(2, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]:
				var at := Vector2(x, z) + offset
				var height := raw_height(at)
				surface.set_color(color_at(at, height).srgb_to_linear())
				surface.add_vertex(Vector3(at.x, height, at.y))
				if coastal:
					water.set_color(Color((height + 64) / 128, 0, 0))
					water.add_vertex(Vector3(at.x, 1.02, at.y))
	var ground := MeshInstance3D.new()
	ground.name = "GigalopolisGround"
	surface.generate_normals()
	surface.index()
	ground.mesh = surface.commit()
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/factory/gigalopolis_ground.gdshader")
	material.set_shader_parameter("paving", GigalopolisMaterials.PAVING)
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	TerrainSupport.mark_permanent(ground)
	TerrainChunks.split_visual(ground)
	water.generate_normals()
	water.index()
	var sea := MeshInstance3D.new()
	sea.name = "GigalopolisShoreWater"
	sea.mesh = water.commit()
	sea.material_override = OceanMaterial.create(Vector2(128, -64), Color("328e9d"), Color("07344e"))
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(sea)
	TerrainChunks.split_visual(sea, false, 64)
