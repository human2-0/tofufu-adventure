class_name FarmFoliage
extends RefCounted
## Instanced field plants and seeded wild ground cover.

static func populate(parent: Node3D, terrain: FarmTerrain, rng: RandomNumberGenerator) -> void:
	var plants: Array[Transform3D] = []
	for row in 24:
		for column in 23:
			var x := -17.0 + column * 1.02
			var z := -11.0 + row * 1.5
			if not terrain.is_field(x, z) or terrain.path_distance(x, z) < 1.7:
				continue
			# Interactive harvest plants occupy the western nursery bed.
			if (x < -8 and z < 0) or Vector2(x + 1, z).length() < 3.2:
				continue
			var scale := rng.randf_range(0.65, 1.05)
			plants.append(Transform3D(Basis(Vector3.UP, rng.randf_range(-0.25, 0.25)).scaled(Vector3.ONE * scale), terrain.point(x, z)))
	var soy := SurfaceTool.new()
	soy.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := CylinderMesh.new()
	stem.top_radius = 0.025
	stem.bottom_radius = 0.04
	stem.height = 1.0
	soy.append_from(stem, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.5, 0)))
	for i in 4:
		for side in [-1.0, 1.0]:
			var leaf := SphereMesh.new()
			leaf.radius = 1.0
			leaf.height = 2.0
			leaf.radial_segments = 6
			leaf.rings = 3
			soy.append_from(leaf, 0, Transform3D(Basis.IDENTITY.scaled(Vector3(0.29, 0.07, 0.17)), Vector3(side * 0.2, 0.35 + i * 0.19, 0)))
	var crop_mesh := soy.commit()
	crop_mesh.surface_set_material(0, MeadowGeometry.material(Color("67994e")))
	_instances(parent, crop_mesh, plants, "SoybeanFields")
	var pods := SphereMesh.new()
	pods.radius = 0.09
	pods.height = 0.32
	pods.radial_segments = 6
	pods.rings = 3
	pods.material = MeadowGeometry.material(Color("c6ce77"))
	var pod_transforms: Array[Transform3D] = []
	for plant in plants:
		for offset in [Vector3(0.14, 0.4, 0.1), Vector3(-0.16, 0.63, 0.1)]:
			pod_transforms.append(plant.translated_local(offset))
	_instances(parent, pods, pod_transforms, "SoyPods")
	_wildflowers(parent, terrain, rng)

static func _wildflowers(parent: Node3D, terrain: FarmTerrain, rng: RandomNumberGenerator) -> void:
	var tufts: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	for i in 2400:
		var x := rng.randf_range(-39, 39)
		var z := rng.randf_range(-39, 39)
		if terrain.path_distance(x, z) < 1.8 or terrain.is_field(x, z) or absf(x - terrain.river_x(z)) < 3.6:
			continue
		if x > 15 and x < 35 and z > -15 and z < 21:
			continue
		if FarmCombatGrounds.is_clearing(x, z):
			continue
		if Vector2(x + 22, z + 22).length() < 6.0:
			continue
		var basis := Basis(Vector3.UP, rng.randf_range(0, TAU))
		tufts.append(Transform3D(basis, terrain.point(x, z, 0.22)))
		if i % 6 == 0:
			flowers.append(Transform3D(basis, terrain.point(x, z, 0.26)))
	var blade := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(-0.13, -0.22, 0), Vector3(0.13, -0.22, 0), Vector3(0.02, 0.32, 0)])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(0.5, 0)])
	blade.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var wind := ShaderMaterial.new()
	wind.shader = preload("res://game/world/meadow_grass.gdshader")
	blade.surface_set_material(0, wind)
	_instances(parent, blade, tufts, "WildGrass")
	var flower := SphereMesh.new()
	flower.radius = 0.12
	flower.height = 0.12
	flower.radial_segments = 5
	flower.rings = 3
	flower.material = MeadowGeometry.material(Color("ffe7ad"))
	_instances(parent, flower, flowers, "Wildflowers")

static func _instances(parent: Node3D, mesh: Mesh, transforms: Array[Transform3D], title: String) -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = title
	instance.multimesh = multi
	parent.add_child(instance)
