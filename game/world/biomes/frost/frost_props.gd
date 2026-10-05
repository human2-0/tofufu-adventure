class_name FrostProps
extends RefCounted
## Snow-clad pines, blue ice and compact glacier stones for Frostcrown.

static func pine(parent: Node3D, at: Vector3, height: float) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.16
	trunk.bottom_radius = 0.3
	trunk.height = height
	trunk.radial_segments = 7
	trunk.material = MeadowGeometry.material(Color("665747"))
	var tree := MeshInstance3D.new()
	tree.mesh = trunk
	tree.position = at + Vector3.UP * height * 0.5
	parent.add_child(tree)
	tree.create_convex_collision()
	for level in 3:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = height * (0.28 - level * 0.045)
		cone.height = height * 0.48
		cone.radial_segments = 6
		cone.material = MeadowGeometry.material(Color("d9f0ef") if level == 2 else Color("4e7d76"))
		var needles := MeshInstance3D.new()
		needles.mesh = cone
		needles.position = at + Vector3.UP * (height * (0.42 + level * 0.22))
		parent.add_child(needles)

static func crystal(parent: Node3D, at: Vector3, height: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.42
	mesh.height = height
	mesh.radial_segments = 5
	mesh.material = MeadowGeometry.material(Color("81d5e4"))
	var shard := MeshInstance3D.new()
	shard.mesh = mesh
	shard.position = at + Vector3.UP * height * 0.5
	parent.add_child(shard)

static func glacier_rock(parent: Node3D, at: Vector3, size: Vector3) -> void:
	MeadowGeometry.rock(parent, at + Vector3.UP * size.y * 0.5, size, Color("9bc8d3"), true)
