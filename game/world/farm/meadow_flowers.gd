class_name MeadowFlowers
extends RefCounted
## Seeded flower islands with five botanical silhouettes, rendered as shared meshes.

const COLORS: Array[Color] = [Color("fff0cf"), Color("dd5542"), Color("6592d0"), Color("9e7bbc"), Color("e898ae")]

static func build(garden: Node3D, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 813
	var blooms: Array[Array] = [[], [], [], [], []]
	var stones: Array[Transform3D] = []
	var soil: Array[Transform3D] = []
	for side in 2:
		for row in 3:
			var local := MeadowVillageGround.flower_center(side, row) - MeadowVillage.FLOWERS
			var center := Vector3(local.x, 0.04, local.y)
			var radii := MeadowVillageGround.flower_radii(side)
			soil.append(Transform3D(Basis.IDENTITY.scaled(Vector3(radii.x, 0.035, radii.y)), center))
			for stone in 22:
				var angle := stone * TAU / 22
				var at := center + Vector3(cos(angle) * radii.x, 0.03, sin(angle) * radii.y)
				stones.append(Transform3D(Basis(Vector3.UP, angle).scaled(Vector3(0.22, 0.11, 0.15)), at))
			for flower in 42:
				var angle := flower * 2.4
				var radius := sqrt(float(flower + 1) / 43) * 0.85
				var at := center + Vector3(cos(angle) * radii.x * radius, 0, sin(angle) * radii.y * radius)
				at += Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.12, 0.12))
				var species := (row + side * 2 + flower / 7) % 5
				var size := rng.randf_range(0.70, 1.15)
				blooms[species].append(Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * size), at))
	_instances(garden, _ellipsoid(Color("67513c")), soil, "RoundedPlantingBeds")
	_instances(garden, _ellipsoid(Color("afa794")), stones, "WeatheredStoneEdging")
	for species in 5: _instances(garden, _flower(species), blooms[species], ["Daisies", "Poppies", "Cornflowers", "Lupins", "Roses"][species])
	_trellis(garden, blooms[4])

static func _flower(species: int) -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 1
	sphere.height = 2
	sphere.radial_segments = 8
	sphere.rings = 3
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.012
	stem.bottom_radius = 0.018
	stem.height = 0.82
	stem.radial_segments = 6
	surface.append_from(stem, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.41, 0)))
	for level in 3:
		for side in [-1.0, 1.0]:
			var basis := Basis(Vector3.FORWARD, side * 0.4).scaled(Vector3(0.18, 0.027, 0.07))
			surface.append_from(sphere, 0, Transform3D(basis, Vector3(side * 0.13, 0.18 + level * 0.17, 0)))
	var result := surface.commit()
	result.surface_set_material(0, MeadowGeometry.material(Color("50814e")))
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if species == 3:
		for tier in 7:
			_petals(surface, sphere, 5, 0.045, Vector3(0.055, 0.048, 0.055), 0.58 + tier * 0.085, tier * 0.6)
	else:
		var petal_count := 4 if species == 1 else 8
		var petal_size := Vector3(0.16, 0.04, 0.065) if species == 0 else Vector3(0.14, 0.055, 0.12)
		if species == 2: petal_size = Vector3(0.15, 0.045, 0.045)
		_petals(surface, sphere, petal_count, 0.14, petal_size, 0.84, 0)
		if species == 4: _petals(surface, sphere, 6, 0.07, Vector3(0.10, 0.07, 0.065), 0.90, 0.4)
	var petals := surface.commit()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, petals.surface_get_arrays(0))
	result.surface_set_material(1, MeadowGeometry.material(COLORS[species]))
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.append_from(sphere, 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.078, 0.055, 0.078)), Vector3(0, 0.88 if species != 3 else 1.16, 0)))
	var center := surface.commit()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, center.surface_get_arrays(0))
	result.surface_set_material(2, MeadowGeometry.material(Color("303b28") if species == 1 else Color("e5b74b")))
	return result

static func _petals(surface: SurfaceTool, sphere: SphereMesh, count: int, radius: float, size: Vector3, height: float, twist: float) -> void:
	for petal in count:
		var angle := petal * TAU / count + twist
		var at := Vector3(cos(angle) * radius, height, sin(angle) * radius)
		surface.append_from(sphere, 0, Transform3D(Basis(Vector3.UP, -angle).scaled(size), at))

static func _trellis(garden: Node3D, roses: Array) -> void:
	var arch := Node3D.new()
	arch.name = "GardenTrellis"
	arch.position = Vector3(-1, 0, -3)
	garden.add_child(arch)
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(arch, Vector3(side * 1.50, 1.30, 0), Vector3(0.13, 2.6, 0.18), Color("9c8c68"), true)
		for level in 6:
			MeadowGeometry.box(arch, Vector3(side * 1.50, 0.5 + level * 0.32, 0), Vector3(0.50, 0.06, 0.08), Color("aa9876"))
			roses.append(Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.35), arch.position + Vector3(side * 1.5, 0.5 + level * 0.32, 0)))
	MeadowGeometry.box(arch, Vector3(0, 2.6, 0), Vector3(3.5, 0.14, 0.24), Color("9c8c68"))
	# A separate bounded batch keeps climbing blooms attached to the trellis.
	_instances(garden, _flower(4), roses.slice(roses.size() - 12), "ClimbingRoses")

static func _ellipsoid(color: Color) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 12
	mesh.rings = 4
	mesh.material = MeadowGeometry.material(color)
	return mesh

static func _instances(parent: Node3D, mesh: Mesh, poses: Array, title: String) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = poses.size()
	for index in poses.size(): multi.set_instance_transform(index, poses[index])
	var view := MultiMeshInstance3D.new()
	view.name = title
	view.multimesh = multi
	view.visibility_range_end = 64
	parent.add_child(view)
