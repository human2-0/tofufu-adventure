class_name MeadowWalnuts
extends RefCounted
## Ridged two-half walnut shells, split kernels and discarded green husks.

static func scatter(tree: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9431
	var shell := _shell_mesh()
	var shells: Array[Transform3D] = []
	for index in 18:
		var angle := index * 2.4
		var radius := rng.randf_range(1.1, 2.4)
		var at := Vector3(sin(angle) * radius, 0.16, cos(angle) * radius)
		var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.9, 1.18))
		shells.append(Transform3D(basis, at))
		if index % 5 == 0:
			MeadowGeometry.rock(tree, at + Vector3(0.18, -0.025, 0.12), Vector3(0.16, 0.075, 0.15), Color("76974f"))
		if index % 6 == 0:
			for half in [-1.0, 1.0]:
				var kernel_at := at + Vector3(half * 0.15, 0.015, -0.30)
				for lobe in 3:
					MeadowGeometry.rock(tree, kernel_at + Vector3(0, lobe * 0.025, (lobe - 1) * 0.055), Vector3(0.075, 0.06, 0.055), Color("d4b787"))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = shell
	multi.instance_count = shells.size()
	for index in shells.size(): multi.set_instance_transform(index, shells[index])
	var view := MultiMeshInstance3D.new()
	view.name = "RidgedWalnutShells"
	view.multimesh = multi
	tree.add_child(view)

static func _shell_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 14
	sphere.rings = 8
	for half in [-1.0, 1.0]:
		surface.append_from(sphere, 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.096, 0.115, 0.15)), Vector3(half * 0.07, 0, 0)))
	var mesh := surface.commit()
	mesh.surface_set_material(0, MeadowGeometry.material(Color("b28c57")))
	# A dark equatorial seam and raised lengthwise corrugations distinguish nuts from pebbles.
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	sphere.radial_segments = 6
	sphere.rings = 3
	for angle in 8:
		for step in 9:
			var theta := -1.25 + step * 0.31
			var phi := angle * TAU / 8
			var at := Vector3(sin(phi) * cos(theta) * 0.158, cos(phi) * cos(theta) * 0.115, sin(theta) * 0.15)
			surface.append_from(sphere, 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.012, 0.012, 0.024)), at))
	for step in 20:
		var angle := step * TAU / 20
		surface.append_from(sphere, 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.008, 0.018, 0.018)), Vector3(0, sin(angle) * 0.114, cos(angle) * 0.147)))
	var ridges := surface.commit()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ridges.surface_get_arrays(0))
	mesh.surface_set_material(1, MeadowGeometry.material(Color("7c5938")))
	return mesh
