class_name MainlandFringe
extends RefCounted
## Continuous terrain shoulders around authored regions, graded to a shared sea.
## Only fills outside existing floors; collision, landing and map use height_at().

var heights: Dictionary[Vector2, float] = {}
static var _ground_cache: Dictionary[int, ArrayMesh] = {}
static var _height_cache: Dictionary[int, Dictionary] = {}
static var _sea_mesh: ArrayMesh

const FADE: float = 48.0
const SEA: float = 1.2
const BED: float = -8.0
const REGIONS: Array[Rect2] = [
	Rect2(-110, -84, 220, 168), Rect2(-80, 84, 160, 132),
	Rect2(-80, 216, 162, 124), Rect2(-80, 340, 160, 140),
	Rect2(-140, -368, 280, 284), GigalopolisTerrain.BOUNDS,
	DofufuTerrain.BOUNDS
]
const BOUNDS := Rect2i(-1040, -432, 1748, 976)

static func contains(at: Vector2) -> bool:
	if not Rect2(BOUNDS).has_point(at) or VolcanicTerrain.contains(at): return false
	for region in REGIONS:
		if at.x >= region.position.x and at.y >= region.position.y and at.x <= region.end.x and at.y <= region.end.y: return false
	return distance_to_land(at) < FADE

static func water_level(at: Vector2) -> float:
	var north := smoothstep(-244.0, -220.0, at.y) * (1.0 - smoothstep(-108.0, -84.0, at.y))
	return lerpf(SEA, OceanTerrain.WATER_LEVEL, north)

static func distance_to_land(at: Vector2) -> float:
	var distance := INF
	for region in REGIONS:
		distance = minf(distance, at.distance_to(at.clamp(region.position, region.end)))
	return distance

static func height_at(world: Meadow, at: Vector2) -> float:
	var cell := (at / 2.0).floor() * 2.0
	var uv := (at - cell) / 2.0
	var a := _raw_height(world, cell)
	var b := _raw_height(world, cell + Vector2(2, 0))
	var c := _raw_height(world, cell + Vector2(0, 2))
	if uv.x + uv.y <= 1: return a + (b - a) * uv.x + (c - a) * uv.y
	var d := _raw_height(world, cell + Vector2(2, 2))
	return d + (c - d) * (1 - uv.x) + (b - d) * (1 - uv.y)

static func _raw_height(world: Meadow, at: Vector2) -> float:
	if world.fringe.heights.has(at): return world.fringe.heights[at]
	var height := _sample_height(world, at)
	world.fringe.heights[at] = height
	return height

static func _sample_height(world: Meadow, at: Vector2) -> float:
	var closest := Vector2.ZERO
	var distance := INF
	var selected := 0
	for index in REGIONS.size():
		var region := REGIONS[index]
		var edge := at.clamp(region.position, region.end)
		var gap := at.distance_to(edge)
		if gap < distance:
			distance = gap
			closest = edge
			selected = index
	var inland := _edge_height(world, closest, selected)
	if distance > 0.001:
		var total := 0.0
		var weight_sum := 0.0
		for index in REGIONS.size():
			var region := REGIONS[index]
			var edge := at.clamp(region.position, region.end)
			var gap := at.distance_to(edge)
			var weight := exp(-pow((gap - distance) / maxf(0.001, distance * 0.7), 2))
			if weight < 0.001: continue
			total += _edge_height(world, edge, index) * weight
			weight_sum += weight
		inland = total / weight_sum
	return lerpf(inland, BED, smoothstep(0.0, FADE, distance))

static func build(world: Meadow) -> void:
	var mesh: ArrayMesh
	if _ground_cache.has(world.world_seed):
		mesh = _ground_cache[world.world_seed]
		world.fringe.heights.assign(_height_cache[world.world_seed])
	else:
		mesh = _ground_mesh(world)
		if _ground_cache.size() >= 4:
			_ground_cache.clear()
			_height_cache.clear()
		_ground_cache[world.world_seed] = mesh
		_height_cache[world.world_seed] = world.fringe.heights.duplicate()
	_attach(world, mesh, "MainlandShoulders", TerrainFinish.create(), true)
	_horizon(world)

static func _ground_mesh(world: Meadow) -> ArrayMesh:
	var ground := SurfaceTool.new()
	ground.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(BOUNDS.position.y, BOUNDS.end.y, 2):
		for x in range(BOUNDS.position.x, BOUNDS.end.x, 2):
			var center := Vector2(x + 1, z + 1)
			if not contains(center): continue
			for offset: Vector2 in [Vector2.ZERO, Vector2(2, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2), Vector2(0, 2)]:
				var at := Vector2(x, z) + offset
				var height := _raw_height(world, at)
				var color := BiomePalette.color_at(at, height, world.world_seed)
				color = color.lerp(Color("d9c393"), smoothstep(3.6, water_level(at), height))
				ground.set_color(color.srgb_to_linear())
				ground.add_vertex(Vector3(at.x, height, at.y))
	ground.generate_normals()
	ground.index()
	return ground.commit()

static func _edge_height(world: Meadow, at: Vector2, region: int) -> float:
	match region:
		0: return world.terrain.height_at(at.x, at.y)
		1: return world.desert.point(at.x, at.y).y
		2: return world.jungle.point(at.x, at.y).y
		3: return world.groatfields.point(at.x, at.y).y
		4: return world.frost.point(at.x, at.y).y if at.y <= -220 else world.ocean.point(at.x, at.y).y
		5: return GigalopolisTerrain.height_at(at)
		_: return world.dofufu_highlands.point(at.x, at.y).y

static func _horizon(world: Meadow) -> void:
	# Coarse grid and shader cutouts close the ocean without duplicating region water.
	if _sea_mesh == null:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for z in range(-1600, 1800, 64):
			for x in range(-2200, 2200, 64):
				for offset: Vector2 in [Vector2.ZERO, Vector2(64, 0), Vector2(0, 64), Vector2(64, 0), Vector2(64, 64), Vector2(0, 64)]:
					surface.set_color(Color(56.0 / 128.0, 0, 0))
					surface.add_vertex(Vector3(x + offset.x, SEA - 0.18, z + offset.y))
		surface.generate_normals()
		surface.index()
		_sea_mesh = surface.commit()
	var material := OceanMaterial.create(Vector2(128, -64), Color("328e9d"), Color("07344e"))
	var exclusions := PackedVector4Array()
	for region in REGIONS + [VolcanicTerrain.BOUNDS]:
		exclusions.append(Vector4(region.position.x, region.position.y, region.end.x, region.end.y))
	material.set_shader_parameter("horizon_water", true)
	material.set_shader_parameter("dry_regions", exclusions)
	_attach(world, _sea_mesh, "ContinuousOuterSea", material, false)

static func _attach(world: Meadow, geometry: ArrayMesh, title: String, material: Material, collision: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.mesh = geometry
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mesh)
	if collision:
		mesh.create_trimesh_collision()
		TerrainSupport.mark_permanent(mesh)
	TerrainChunks.split_visual(mesh, false, TerrainChunks.SIZE if collision else 512.0)
