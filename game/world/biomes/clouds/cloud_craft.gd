class_name CloudCraft
extends RefCounted
## Small authored mesh pieces, with no additional gameplay collision.

static func view(parent: Node3D, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.position = at
	result.material_override = material
	if mesh is ArrayMesh: result.set_meta("static_ornament_mesh", true)
	parent.add_child(result)
	return result

static func box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return view(parent, mesh, at, material)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, material: Material, top: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 20
	return view(parent, mesh, at, material)

static func ring(parent: Node3D, at: Vector3, radius: float, width: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - width
	mesh.outer_radius = radius
	mesh.rings = 24
	mesh.ring_segments = 8
	return view(parent, mesh, at, material)

static func lathe(parent: Node3D, at: Vector3, profile: Array[Vector2], material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(profile.size() - 1):
		for side in 24:
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var point := profile[row + corner.y]
				var angle: float = (side + corner.x) * TAU / 24.0
				surface.set_uv(Vector2(float(side + corner.x) / 24, float(row + corner.y) / (profile.size() - 1)))
				surface.add_vertex(Vector3(cos(angle) * point.x, point.y, sin(angle) * point.x))
	surface.generate_normals()
	return view(parent, surface.commit(), at, material)

static func body(parent: Node3D, at: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at + Vector3.UP * height * 0.5
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	parent.add_child(body)
