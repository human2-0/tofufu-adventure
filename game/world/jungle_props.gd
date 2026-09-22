class_name JungleProps
extends RefCounted
## Original low-poly tropical silhouettes with solid trunks and decorative foliage.

static func palm(parent: Node3D, at: Vector3, height: float, angle: float) -> void:
	var trunk := trunk_mesh(parent, at + Vector3(0, height * 0.5, 0), height)
	trunk.rotation.z = 0.08
	for i in 7:
		var turn := angle + i * TAU / 7
		var direction := Vector3(cos(turn), 0, sin(turn))
		leaf(parent, at + Vector3(-height * 0.08, height, 0), direction, height * 0.36, Color("398660") if i % 2 == 0 else Color("77a955"))
	for i in 3:
		MeadowGeometry.rock(parent, at + Vector3(-0.4 + i * 0.3, height - 0.3, 0), Vector3.ONE * 0.25, Color("a69752"))

static func leaf(parent: Node3D, at: Vector3, direction: Vector3, length: float, color: Color) -> void:
	var side := direction.cross(Vector3.UP) * length * 0.23
	var middle := at + direction * length * 0.48 + Vector3.UP * length * 0.18
	var tip := at + direction * length + Vector3.DOWN * length * 0.23
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in [at, middle + side, middle + Vector3.UP * 0.2, at, middle + Vector3.UP * 0.2, middle - side, middle + side, tip, middle + Vector3.UP * 0.2, middle + Vector3.UP * 0.2, tip, middle - side]:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	var material := MeadowGeometry.material(color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	parent.add_child(mesh)

static func fern(parent: Node3D, at: Vector3, size: float) -> void:
	for i in 5:
		var angle := i * TAU / 5
		leaf(parent, at, Vector3(cos(angle), 0, sin(angle)), size, Color("78ad60"))

static func arch(parent: Node3D, at: Vector3, width: float, height: float) -> void:
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(parent, at + Vector3(side * width * 0.5, height * 0.5, 0), Vector3(1.6, height, 1.8), Color("637b6c"), true)
		MeadowGeometry.rock(parent, at + Vector3(side * width * 0.5, height, 0), Vector3(1.1, 0.35, 1.1), Color("88a85e"))
		for i in 3:
			MeadowGeometry.box(parent, at + Vector3(side * width * 0.5, 1 + i * 1.4, 0.93), Vector3(1.0, 0.14, 0.05), Color("bed08a"))
	MeadowGeometry.box(parent, at + Vector3.UP * height, Vector3(width + 2, 1, 2), Color("728b72"), true)
	for i in 6:
		MeadowGeometry.box(parent, at + Vector3(-width * 0.5 + i * width / 5, height - 0.6, 1.05), Vector3(0.09, 1.8 + sin(i) * 0.6, 0.1), Color("487c4c"))

static func trunk_mesh(parent: Node3D, at: Vector3, height: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.22
	mesh.bottom_radius = 0.46
	mesh.height = height
	mesh.radial_segments = 7
	mesh.material = MeadowGeometry.material(Color("796343"))
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	instance.create_convex_collision()
	return instance
