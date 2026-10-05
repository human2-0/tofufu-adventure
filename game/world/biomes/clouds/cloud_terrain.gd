class_name CloudTerrain
extends RefCounted
## High cloud islands and connecting ribbons share one rippled collision surface.

const ALTITUDE: float = 58.0
const CENTER := Vector2(-8, 266)
const LANDING := Vector2(-8, 247)
const ISLANDS: Array[Vector3] = [Vector3(0, 0, 17), Vector3(0, -19, 9), Vector3(27, 5, 11), Vector3(-25, 9, 10), Vector3(8, 29, 12)]

static func contains(at: Vector2) -> bool:
	return distance_to_edge(at) <= 0.0

static func distance_to_edge(at: Vector2) -> float:
	var local := at - CENTER
	var distance := INF
	for island in ISLANDS:
		var center := Vector2(island.x, island.y)
		distance = minf(distance, local.distance_to(center) - island.z)
		var closest := Geometry2D.get_closest_point_to_segment(local, Vector2.ZERO, center)
		distance = minf(distance, local.distance_to(closest) - 3.5)
	return distance + WorldContours.noise(at / 6.0, 4327) * 0.65

static func height_at(x: float, z: float) -> float:
	var local := Vector2(x, z) - CENTER
	return ALTITUDE + sin(local.x * 0.18) * 0.45 + cos(local.y * 0.22) * 0.35 + 1.2 * exp(-local.length_squared() / 160.0)

static func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, height_at(x, z) + lift, z)

static func build(parent: Node3D) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(238, 309):
		for x in range(-45, 32):
			if distance_to_edge(Vector2(x + 0.5, z + 0.5)) > 1.0: continue
			var at := Vector2(x, z)
			_triangle(surface, [at, at + Vector2.RIGHT, at + Vector2.DOWN])
			_triangle(surface, [at + Vector2.RIGHT, at + Vector2.ONE, at + Vector2.DOWN])
	surface.generate_normals()
	var ground := MeshInstance3D.new()
	ground.name = "WalkableClouds"
	ground.mesh = surface.commit()
	# Leave headroom for the world's bright daylight so pastel swirls stay visible.
	var material := MeadowGeometry.material(Color(0.84, 0.84, 0.84))
	material.next_pass = null
	material.vertex_color_use_as_albedo = true
	ground.material_override = material
	parent.add_child(ground)
	ground.create_trimesh_collision()
	return ground

static func _triangle(surface: SurfaceTool, corners: Array[Vector2]) -> void:
	# Clip boundary triangles to rounded islands instead of leaving square ledges.
	var polygon: Array[Vector2] = []
	var previous: Vector2 = corners.back()
	for current in corners:
		var inside := contains(current)
		if inside != contains(previous): polygon.append(_boundary(previous, current))
		if inside: polygon.append(current)
		previous = current
	for i in range(1, polygon.size() - 1):
		for at: Vector2 in [polygon[0], polygon[i], polygon[i + 1]]:
			var swirl := sin(at.x * 0.19 + cos(at.y * 0.2) * 2.0) * 0.5 + 0.5
			var color := Color("c9c5f1").lerp(Color("fff4dd"), swirl)
			color = color.lerp(Color("d3f2f5"), (cos(at.y * 0.3) + 1.0) * 0.16)
			surface.set_color(color)
			surface.add_vertex(point(at.x, at.y))

static func _boundary(a: Vector2, b: Vector2) -> Vector2:
	var low := a
	var high := b
	var a_inside := contains(a)
	for step in 12:
		var mid := (low + high) * 0.5
		if contains(mid) == a_inside: low = mid
		else: high = mid
	return (low + high) * 0.5
