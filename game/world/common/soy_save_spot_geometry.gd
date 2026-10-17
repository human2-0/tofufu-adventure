class_name SoySaveSpotGeometry
extends RefCounted
## Rounded soybean silhouette with generated atlas materials and real leaf UVs.

const ATLAS := preload("res://assets/environment/soy_save_spot/surfaces.png")

static func material(tile: Vector2, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_texture = ATLAS
	result.albedo_color = tint
	result.uv1_scale = Vector3(0.48, 0.48, 1)
	result.uv1_offset = Vector3(tile.x * 0.5 + 0.01, tile.y * 0.5 + 0.01, 0)
	result.roughness = 0.88
	return result

static func build(parent: Node3D, pods: StandardMaterial3D, gold: StandardMaterial3D) -> void:
	var stone := material(Vector2(0, 1))
	var leaf := material(Vector2.ZERO)
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	var foliage := leaf_mesh()
	var pod := pod_mesh()
	var stem := material(Vector2.ZERO, Color("a7c889"))
	var base := CylinderMesh.new()
	base.top_radius = 0.72
	base.bottom_radius = 0.9
	base.height = 0.28
	base.radial_segments = 12
	mesh(parent, base, Vector3(0, 0.14, 0), Vector3.ONE, stone)
	rod(parent, Vector3(0, 0.25, 0), Vector3(0, 2.45, 0), 0.055, stem)
	for tier in 4:
		for side in [-1.0, 1.0]:
			var start := Vector3(0, 0.65 + tier * 0.43, 0)
			var end := start + Vector3(side * (0.68 - tier * 0.1), 0.28, sin(tier * 2.4) * 0.3)
			rod(parent, start, end, 0.025, stem)
			for angle in [-0.8, 0.0, 0.8]:
				var blade := mesh(parent, foliage, end, Vector3.ONE * 0.6, leaf)
				blade.rotation = Vector3(-0.25, angle + (PI if side < 0 else 0), 0.2)
			if tier < 3:
				var fruit := mesh(parent, pod, end + Vector3(side * 0.08, -0.3, 0), Vector3.ONE, pods)
				fruit.rotation.z = side * 0.14
	var seed := SphereMesh.new()
	seed.radial_segments = 20
	seed.rings = 10
	mesh(parent, seed, Vector3(0, 2.5, 0), Vector3(0.32, 0.4, 0.26), gold)

static func leaf_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points: Array[Vector3] = [Vector3.ZERO, Vector3(0.45, 0.1, -0.36), Vector3(1, 0, 0), Vector3(0.45, 0.1, 0.36), Vector3(0.48, 0.18, 0)]
	var uvs: Array[Vector2] = [Vector2(0.5, 1), Vector2(0, 0.5), Vector2(0.5, 0), Vector2(1, 0.5), Vector2(0.5, 0.5)]
	for index in [0, 1, 4, 1, 2, 4, 2, 3, 4, 3, 0, 4]:
		surface.set_uv(uvs[index])
		surface.add_vertex(points[index])
	surface.generate_normals()
	return surface.commit()

static func pod_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 18:
		for side in 10:
			for offset: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var t := (ring + offset.x) / 18.0
				var angle := (side + offset.y) * TAU / 10.0
				var radius := pow(maxf(0, sin(t * PI)), 0.45) * (0.08 + pow(sin(t * PI * 3), 2) * 0.045)
				surface.set_uv(Vector2((side + offset.y) / 10.0, t))
				surface.add_vertex(Vector3(cos(angle) * radius, (0.5 - t) * 0.65, sin(angle) * radius * 0.7))
	surface.generate_normals()
	return surface.commit()

static func rod(parent: Node3D, start: Vector3, end: Vector3, radius: float, mat: Material) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius * 0.65
	cylinder.bottom_radius = radius
	cylinder.height = start.distance_to(end)
	cylinder.radial_segments = 8
	var part := mesh(parent, cylinder, (start + end) * 0.5, Vector3.ONE, mat)
	part.quaternion = Quaternion(Vector3.UP, (end - start).normalized())

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = mat
	instance.position = at
	instance.visibility_range_end = 65.0
	instance.visibility_range_end_margin = 5.0
	instance.scale = size
	parent.add_child(instance)
	return instance
