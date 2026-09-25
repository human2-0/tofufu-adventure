class_name DesertProps
extends RefCounted
## Low-poly desert silhouettes: hardy plants, sandstone and an inviting oasis.

static func cactus(parent: Node3D, at: Vector3, height: float) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.25
	trunk.bottom_radius = 0.36
	trunk.height = height
	trunk.radial_segments = 7
	trunk.material = MeadowGeometry.material(Color("527c54"))
	var body := MeshInstance3D.new()
	body.mesh = trunk
	body.position = at + Vector3.UP * height * 0.5
	parent.add_child(body)
	body.create_convex_collision()
	for side in [-1.0, 1.0]:
		var arm := MeadowGeometry.box(parent, at + Vector3(side * 0.38, height * 0.57, 0), Vector3(0.72, 0.18, 0.2), Color("638c55"))
		arm.rotation.z = side * -0.4

static func yucca(parent: Node3D, at: Vector3, size: float) -> void:
	for i in 8:
		var angle := i * TAU / 8.0
		var blade := MeadowGeometry.box(parent, at + Vector3(cos(angle) * size * 0.3, size * 0.22, sin(angle) * size * 0.3), Vector3(size * 0.12, size * 0.8, size * 0.12), Color("789157"))
		blade.rotation.z = sin(angle) * 0.85
		blade.rotation.x = cos(angle) * 0.85

static func dry_shrub(parent: Node3D, at: Vector3, size: float) -> void:
	for i in 5:
		var angle := i * TAU / 5.0
		var twig := MeadowGeometry.box(parent, at + Vector3(cos(angle) * size * 0.25, size * 0.18, sin(angle) * size * 0.25), Vector3(size * 0.08, size * 0.55, size * 0.08), Color("9b7a4d"))
		twig.rotation.z = sin(angle) * 0.72

static func palm(parent: Node3D, at: Vector3, height: float, angle: float) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.36
	trunk.height = height
	trunk.radial_segments = 7
	trunk.material = MeadowGeometry.material(Color("806447"))
	var tree := MeshInstance3D.new()
	tree.mesh = trunk
	tree.position = at + Vector3.UP * height * 0.5
	parent.add_child(tree)
	for i in 7:
		var turn := angle + i * TAU / 7.0
		var leaf := MeadowGeometry.box(parent, at + Vector3(cos(turn) * height * 0.18, height, sin(turn) * height * 0.18), Vector3(height * 0.36, 0.08, height * 0.13), Color("5f955a"))
		leaf.rotation.y = -turn
		leaf.rotation.z = 0.22

static func sandstone(parent: Node3D, at: Vector3, size: Vector3) -> void:
	MeadowGeometry.rock(parent, at + Vector3.UP * size.y * 0.5, size, Color("b87545"), true)
	MeadowGeometry.rock(parent, at + Vector3(0.35, size.y * 0.92, -0.15), size * Vector3(0.72, 0.28, 0.72), Color("dd9d57"))
