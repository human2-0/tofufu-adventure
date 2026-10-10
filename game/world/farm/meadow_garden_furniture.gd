class_name MeadowGardenFurniture
extends RefCounted
## Weathered covered Polish well and a slatted bench looking toward the vegetables.

static func build(world: Meadow) -> void:
	_bench(world, world.ground_point(56.5, -25))
	_well(world, world.ground_point(56.5, -19))

static func _bench(world: Meadow, at: Vector3) -> void:
	var bench := Node3D.new()
	bench.name = "VegetableFacingBench"
	bench.position = at
	bench.rotation.y = -PI / 2
	world.add_child(bench)
	for slat in 4:
		MeadowGeometry.box(bench, Vector3(0, 0.65, -0.23 + slat * 0.15), Vector3(2.6, 0.10, 0.12), Color("956948"), true)
	for slat in 3:
		MeadowGeometry.box(bench, Vector3(0, 0.97 + slat * 0.18, 0.31), Vector3(2.6, 0.13, 0.10), Color("a57750"), true)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(bench, Vector3(side * 1, 0.33, 0), Vector3(0.14, 0.65, 0.7), Color("485b52"), true)
		MeadowGeometry.box(bench, Vector3(side * 1.25, 0.87, 0), Vector3(0.10, 0.10, 0.7), Color("665443"))
	MeadowSurfaces.apply_tree(bench)

static func _well(world: Meadow, at: Vector3) -> void:
	var well := Node3D.new()
	well.name = "OldStudnia"
	well.position = at
	world.add_child(well)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.75
	ring.outer_radius = 1.12
	ring.rings = 24
	ring.ring_segments = 8
	ring.material = MeadowSurfaces.material("concrete", Color("dbd2bc"))
	for layer in 3:
		_mesh(well, ring, Vector3(0, 0.24 + layer * 0.27, 0))
		for joint in 14:
			var angle := TAU * (joint + layer * 0.5) / 14
			var line := MeadowGeometry.box(well, Vector3(sin(angle), 0.23 + layer * 0.27, cos(angle)) * Vector3(1.1, 1, 1.1), Vector3(0.025, 0.20, 0.07), Color("827f72"))
			line.rotation.y = angle
	MeadowGeometry.rock(well, Vector3(0, 0.30, 0), Vector3(0.76, 0.015, 0.76), Color("4d7777"))
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(well, Vector3(side * 1.18, 1.65, 0), Vector3(0.19, 3.3, 0.19), Color("766044"), true)
		var roof := MeadowGeometry.box(well, Vector3(0, 3.1, side * 0.58), Vector3(3.2, 0.14, 1.45), Color("584738"))
		roof.rotation.x = side * 0.37
		MeadowSurfaces.apply(roof, "roof")
		for plank in 10:
			MeadowGeometry.box(well, Vector3(-1.44 + plank * 0.32, 3.22, side * 0.68), Vector3(0.025, 0.04, 1.2), Color("80634b")).rotation.x = side * 0.37
	var windlass := _cylinder(well, Vector3(0, 2.07, 0), 0.14, 2.45, Color("9d7953"))
	windlass.rotation.z = PI / 2
	MeadowGeometry.box(well, Vector3(1.46, 1.91, 0), Vector3(0.09, 0.4, 0.09), Color("596360"))
	MeadowGeometry.box(well, Vector3(1.52, 1.73, 0), Vector3(0.23, 0.09, 0.09), Color("89694b"))
	MeadowGeometry.box(well, Vector3(0, 1.58, 0), Vector3(0.025, 1.0, 0.025), Color("ad9b71"))
	_bucket(well, Vector3(0, 0.98, 0))
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.12
	cylinder.height = 0.9
	shape.shape = cylinder
	shape.position.y = 0.45
	blocker.add_child(shape)
	well.add_child(blocker)
	MeadowSurfaces.apply_tree(well)

static func _bucket(well: Node3D, at: Vector3) -> void:
	var bucket := _cylinder(well, at, 0.22, 0.32, Color("997b55"))
	for level in [-0.11, 0.11]:
		var band := TorusMesh.new()
		band.inner_radius = 0.21
		band.outer_radius = 0.235
		band.rings = 16
		band.ring_segments = 6
		band.material = MeadowGeometry.material(Color("59615b"))
		_mesh(bucket, band, Vector3(0, level, 0))
	var handle := TorusMesh.new()
	handle.inner_radius = 0.205
	handle.outer_radius = 0.22
	handle.rings = 16
	handle.ring_segments = 6
	handle.material = MeadowGeometry.material(Color("59615b"))
	_mesh(bucket, handle, Vector3(0, 0.16, 0)).rotation.x = PI / 2

static func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.85
	mesh.height = height
	mesh.radial_segments = 16
	mesh.material = MeadowSurfaces.material("timber", Color.WHITE.lerp(color, 0.22))
	return _mesh(parent, mesh, at)

static func _mesh(parent: Node3D, mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	return instance
