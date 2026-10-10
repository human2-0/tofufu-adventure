class_name MeadowGrass
extends RefCounted
## Fine rooted ribbons, seeded once in independently culled eight-metre patches.

const PATCH_SIZE: float = 8.0
const SPACING: float = 0.262
const BLADES_PER_TUFT: int = 2

static func populate(parent: Node3D, terrain: FarmTerrain, rng: RandomNumberGenerator) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/world/farm/meadow_grass.gdshader")
	var mesh := _blade()
	mesh.surface_set_material(0, material)
	var patches: Dictionary[Vector2i, Array] = {}
	for row in int(128.0 / SPACING):
		for column in int(152.0 / SPACING):
			var x := -76.0 + (column + rng.randf()) * SPACING
			var z := -64.0 + (row + rng.randf()) * SPACING
			if not habitat(terrain, x, z): continue
			var key := Vector2i(floori(x / PATCH_SIZE), floori(z / PATCH_SIZE))
			if not patches.has(key): patches[key] = []
			var size := Vector3(rng.randf_range(0.6, 1.1), rng.randf_range(0.55, 1.25), 1.0)
			var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(size)
			patches[key].append(Transform3D(basis, terrain.point(x, z, -0.025)))
	var cover := Node3D.new()
	cover.name = "WildGrass"
	parent.add_child(cover)
	for key: Vector2i in patches:
		_patch(cover, mesh, key, patches[key], rng)
	return material

static func habitat(terrain: FarmTerrain, x: float, z: float) -> bool:
	if terrain.path_distance(x, z) < 1.8 or terrain.is_field(x, z): return false
	if absf(x - terrain.river_x(z)) < 3.6: return false
	if MeadowVillage.BOUNDS.has_point(Vector2(x, z)) and not MeadowVillageGround.lawn(Vector2(x, z)): return false
	if FarmCombatGrounds.is_clearing(x, z): return false
	return Vector2(x + 22, z + 22).length() >= 6.0

static func _patch(parent: Node3D, mesh: Mesh, key: Vector2i, transforms: Array, rng: RandomNumberGenerator) -> void:
	var origin := Vector3(key.x * PATCH_SIZE, 0, key.y * PATCH_SIZE)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		var pose: Transform3D = transforms[i]
		pose.origin -= origin
		multi.set_instance_transform(i, pose)
		multi.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), rng.randf(), 1))
	var patch := MultiMeshInstance3D.new()
	patch.name = "Patch_%s_%s" % [key.x, key.y]
	patch.position = origin
	patch.multimesh = multi
	# Include maximum shader displacement in the culling bounds.
	patch.extra_cull_margin = 1.0
	patch.visibility_range_end = 48.0
	patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(patch)

static func _blade() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for blade in BLADES_PER_TUFT:
		var rotation := Basis(Vector3.UP, blade * 2.1)
		var offset := Vector3(-0.06, 0, 0.02) if blade == 0 else Vector3(0.07, 0, -0.04)
		var scale := 1.0 if blade == 0 else 0.82
		for ring in 3:
			var height := ring / 3.0
			var half_width := 0.023 * (1.0 - height * 0.8)
			for side in [-1.0, 1.0]:
				var at := Vector3(side * half_width, height * 0.56, height * height * 0.09)
				vertices.append(rotation * at * scale + offset)
				uvs.append(Vector2((side + 1) * 0.5, 1.0 - height))
		vertices.append(rotation * Vector3(0.006, 0.56, 0.12) * scale + offset)
		uvs.append(Vector2(0.5, 0))
		for index in [0, 2, 1, 1, 2, 3, 2, 4, 3, 3, 4, 5, 4, 6, 5]:
			indices.append(index + blade * 7)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for blade in BLADES_PER_TUFT:
		var normal := Basis(Vector3.UP, blade * 2.1) * Vector3.FORWARD
		for vertex in 7: normals[blade * 7 + vertex] = normal
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	# Keep the full curved ribbons nearby; distant patches reuse root/tip vertices.
	var medium := PackedInt32Array()
	var distant := PackedInt32Array()
	for blade in BLADES_PER_TUFT:
		for index in [0, 4, 1, 1, 4, 5, 4, 6, 5]: medium.append(index + blade * 7)
		for index in [0, 6, 1]: distant.append(index + blade * 7)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {0.003: medium, 0.009: distant})
	return mesh
