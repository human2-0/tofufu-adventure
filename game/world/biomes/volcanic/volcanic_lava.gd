class_name VolcanicLava
extends RefCounted
## Authored rivers connect the crater to the sea; castle moat has one stone crossing.

const POOL_RADIUS: float = 11.0
const POOL_LIFT: float = 1.0
const POOL_THICKNESS: float = 0.6
const RIVERS: Array[Array] = [
	[Vector2(450, 380), Vector2(423, 348), Vector2(408, 308), Vector2(387, 278), Vector2(357, 262), Vector2(320, 250), Vector2(280, 265)],
	[Vector2(450, 380), Vector2(486, 347), Vector2(522, 338), Vector2(556, 356), Vector2(601, 352), Vector2(642, 333), Vector2(669, 324)],
	[Vector2(450, 380), Vector2(472, 417), Vector2(487, 451), Vector2(473, 489), Vector2(502, 514), Vector2(510, 540)]]

static func river_distance(at: Vector2) -> float:
	var distance := INF
	for river in RIVERS:
		for i in range(1, river.size()):
			distance = minf(distance, at.distance_to(Geometry2D.get_closest_point_to_segment(at, river[i - 1], river[i])))
	return distance

static func molten(at: Vector3) -> bool:
	var planar := Vector2(at.x, at.z)
	if not VolcanicTerrain.contains(planar): return false
	if planar.distance_to(VolcanicTerrain.VOLCANO) < POOL_RADIUS:
		var surface := VolcanicTerrain.point(VolcanicTerrain.VOLCANO).y + POOL_LIFT + POOL_THICKNESS * 0.5
		if at.y < surface + 0.05: return true
	var local := planar - LavaCastle.CENTER
	var moat := maxf(absf(local.x) / 37.0, absf(local.y) / 38.0)
	var bridge := absf(local.x) < 2.8 and local.y > 27.0
	if moat > 0.83 and moat < 1.13 and not bridge and at.y < 5.0: return true
	return river_distance(planar) < 2.2 and at.y < VolcanicTerrain.height_at(at.x, at.z) + 0.55

static func build(parent: Node3D, grid: VolcanicGroundGrid) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/biomes/volcanic/lava.gdshader")
	for river in RIVERS:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(1, river.size()):
			var start: Vector2 = river[i - 1]
			var end: Vector2 = river[i]
			var side := (end - start).normalized().orthogonal() * 2.7
			var steps := ceili(start.distance_to(end))
			for step in steps:
				var a := start.lerp(end, float(step) / steps)
				var b := start.lerp(end, float(step + 1) / steps)
				for at: Vector2 in [a - side, b - side, a + side, b - side, b + side, a + side]:
					surface.set_uv(at * 0.15)
					surface.add_vertex(grid.point(at, 0.32))
		surface.generate_normals()
		surface.index()
		var mesh := MeshInstance3D.new()
		mesh.name = "FlowingLavaRiver"
		mesh.mesh = surface.commit()
		mesh.material_override = material
		parent.add_child(mesh)
	for spec in [Vector4(-36, 0, 8, 84), Vector4(36, 0, 8, 84), Vector4(0, -36, 64, 10), Vector4(0, 36, 64, 10)]:
		var mesh := MeadowGeometry.box(parent, Vector3(LavaCastle.CENTER.x + spec.x, 4.12, LavaCastle.CENTER.y + spec.y), Vector3(spec.z, 0.15, spec.w), Color.WHITE)
		mesh.material_override = material
	_pool(parent, material)
	return material

static func _pool(parent: Node3D, material: ShaderMaterial) -> void:
	var pool := MeshInstance3D.new()
	pool.name = "CraterLavaPool"
	var disk := CylinderMesh.new()
	disk.top_radius = POOL_RADIUS
	disk.bottom_radius = POOL_RADIUS
	disk.height = POOL_THICKNESS
	disk.radial_segments = 32
	pool.mesh = disk
	pool.position = VolcanicTerrain.point(VolcanicTerrain.VOLCANO, POOL_LIFT)
	pool.material_override = material
	parent.add_child(pool)
