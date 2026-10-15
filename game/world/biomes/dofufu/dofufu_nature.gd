class_name DofufuNature
extends RefCounted
## Seeded pine groves, bamboo, exposed boulders and trail cairns.

static func build(parent: Node3D, terrain: DofufuTerrain) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = terrain.noise.seed
	for i in 460:
		var x := rng.randf_range(-830, -125)
		var z := rng.randf_range(-170, 170)
		var at2 := Vector2(x, z)
		if DofufuTerrain.trail_distance(at2) < 18 or terrain.paths.distance_to(at2) < 7: continue
		if at2.distance_to(DofufuMountainPaths.LOOKOUT) < 10: continue
		var at := terrain.point(x, z)
		if i % 5 == 0:
			MeadowGeometry.rock(parent, at + Vector3.UP * 0.4, Vector3(2.5, 1.6, 2), Color("7b8175"), true)
		elif i % 3 == 0:
			_bamboo(parent, at, rng.randf_range(3, 5))
		else:
			_pine(parent, at, rng.randf_range(4, 8))
	for x in range(-140, -840, -35):
		var at := terrain.point(x, DofufuTerrain.trail_z(x) + 7)
		for tier in 3:
			MeadowGeometry.rock(parent, at + Vector3.UP * (0.2 + tier * 0.3), Vector3.ONE * (0.55 - tier * 0.13), Color("b3b3a0"))
	_edge_plants(parent, terrain)
	# Conceal the retreat from the main trail without filling its walkable apron.
	for at in [Vector2(-553, 113), Vector2(-552, 119), Vector2(-589, 108)]:
		_bamboo(parent, terrain.point(at.x, at.y), 5.2)

static func _edge_plants(parent: Node3D, terrain: DofufuTerrain) -> void:
	# One mesh per short stretch, with no per-leaf nodes or collision obstacles.
	for section in range(-140, -840, -50):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var origin := terrain.trail_point(section)
		for x in range(section, section - 50, -4):
			var slope := (DofufuTerrain.trail_z(x + 0.25) - DofufuTerrain.trail_z(x - 0.25)) * 2
			var normal := Vector2(-slope, 1).normalized()
			for side in [-1, 1]:
				var at: Vector2 = Vector2(x, DofufuTerrain.trail_z(x)) + normal * side * (9 + posmod(x, 5))
				if terrain.paths.distance_to(at) < 5: continue
				var base := terrain.point(at.x, at.y, 0.03) - origin
				for leaf in 7:
					var angle := leaf * TAU / 7 + x
					_leaf(surface, base, Vector3(cos(angle) * 0.6, 0.4 + posmod(x, 3) * 0.12, sin(angle) * 0.6), Color("4c7442").lightened(leaf * 0.025))
		surface.generate_normals()
		var material := MeadowGeometry.material(Color.WHITE)
		material.vertex_color_use_as_albedo = true
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		material.next_pass = null
		surface.set_material(material)
		var view := MeshInstance3D.new()
		view.mesh = surface.commit()
		view.position = origin
		view.set_meta("static_ornament_mesh", true)
		parent.add_child(view)

static func _pine(parent: Node3D, at: Vector3, height: float) -> void:
	MeadowGeometry.box(parent, at + Vector3.UP * height * 0.4, Vector3(0.35, height * 0.8, 0.35), Color("64513c"), true)
	for tier in 3:
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0
		mesh.bottom_radius = height * (0.3 - tier * 0.06)
		mesh.height = height * 0.52
		mesh.radial_segments = 9
		mesh.material = MeadowGeometry.material(Color("2d5143").lightened(tier * 0.07))
		var view := MeshInstance3D.new()
		view.mesh = mesh
		view.position = at + Vector3.UP * height * (0.42 + tier * 0.2)
		parent.add_child(view)

static func _bamboo(parent: Node3D, at: Vector3, height: float) -> void:
	# Build one coloured mesh per clump rather than a node for every leaf/joint.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for stalk in 3:
		var base := Vector3(stalk * 0.4, 0, stalk * 0.2)
		_tube(surface, base + Vector3.UP * height * 0.5, 0.08, height, Color("698851"))
		for joint in 6:
			_tube(surface, base + Vector3.UP * (height * joint / 6), 0.095, 0.08, Color("a3ae6c"))
		for fan in 4:
			var center := base + Vector3.UP * height * (0.5 + fan * 0.13)
			for leaf in 5:
				var angle := fan * 2.4 + leaf * 0.48
				var reach := Vector3(cos(angle), 0.25 - leaf * 0.12, sin(angle)) * 1.4
				_leaf(surface, center, reach, Color("48784b").lightened(leaf * 0.025))
	surface.generate_normals()
	surface.index()
	var material := MeadowGeometry.material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.next_pass = null
	surface.set_material(material)
	var view := MeshInstance3D.new()
	view.mesh = surface.commit()
	view.set_meta("static_ornament_mesh", true)
	view.position = at
	parent.add_child(view)

static func _tube(surface: SurfaceTool, at: Vector3, radius: float, height: float, color: Color) -> void:
	surface.set_color(color.srgb_to_linear())
	for side in 6:
		var angle := side * TAU / 6
		var next_angle := (side + 1) * TAU / 6
		var a := Vector3(cos(angle) * radius, -height * 0.5, sin(angle) * radius)
		var b := Vector3(cos(next_angle) * radius, -height * 0.5, sin(next_angle) * radius)
		var c := a + Vector3.UP * height
		var d := b + Vector3.UP * height
		for vertex in [a, c, b, b, c, d, c, Vector3.UP * height * 0.5, d]:
			surface.add_vertex(at + vertex)

static func _leaf(surface: SurfaceTool, at: Vector3, reach: Vector3, color: Color) -> void:
	surface.set_color(color.srgb_to_linear())
	var across := Vector3(-reach.z, 0, reach.x).normalized() * 0.13
	for corner in [Vector3.ZERO, reach * 0.45 + across, reach, Vector3.ZERO, reach, reach * 0.45 - across]:
		surface.add_vertex(at + corner)
