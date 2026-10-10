extends SceneTree
## Authored leaf positions, surfaces and independently controlled views survive baking.
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var scenery := Node3D.new()
	scenery.position = Vector3(100, 5, -50)
	root.add_child(scenery)
	JungleProps.leaf(scenery, Vector3(2, 3, 7), Vector3.RIGHT, 2, Color.GREEN)
	JungleProps.leaf(scenery, Vector3(3, 3, 7), Vector3.RIGHT, 2, Color.GREEN)
	var points: Array[Vector3] = []
	for leaf: MeshInstance3D in scenery.get_children():
		for vertex in leaf.mesh.get_faces(): points.append(leaf.to_global(vertex))
	StaticDecorationBatch.build(scenery)
	check(scenery.get_child_count() == 1, "compatible immutable leaf surfaces share a spatial batch")
	var batch := scenery.get_child(0) as MeshInstance3D
	var faces := batch.mesh.get_faces()
	check(faces.size() == points.size(), "baking retains every authored leaf triangle")
	for i in faces.size(): check(batch.to_global(faces[i]).is_equal_approx(points[i]), "baking retains exact leaf world positions")
	check(batch.mesh.surface_get_material(0).cull_mode == BaseMaterial3D.CULL_DISABLED, "folded leaves retain their two-sided material")
	check(batch.mesh.get_aabb().size.x < StaticDecorationBatch.TILE_SIZE, "leaf bounds remain local to a spatial tile")
	var one_sided := MeadowGeometry.box(scenery, Vector3(2, 3, 7), Vector3.ONE, Color.GREEN)
	var glowing := MeadowGeometry.box(scenery, Vector3(2, 3, 8), Vector3.ONE, Color.GREEN)
	(glowing.mesh.material as StandardMaterial3D).emission_enabled = true
	StaticDecorationBatch.build(scenery)
	check(not is_instance_valid(one_sided) and not is_instance_valid(glowing) and scenery.get_child_count() == 3, "different lighting and cull states cannot merge into the same material")
	var cutaway := MeadowGeometry.box(scenery, Vector3.ZERO, Vector3.ONE, Color.WHITE)
	cutaway.set_meta("cutaway_ornament", true)
	var ranged := MeadowGeometry.box(scenery, Vector3.ZERO, Vector3.ONE, Color.WHITE)
	ranged.visibility_range_begin = 22
	var layered := MeadowGeometry.box(scenery, Vector3(2, 3, 9), Vector3.ONE, Color.GREEN)
	layered.layers = 2
	StaticDecorationBatch.build(scenery)
	check(is_instance_valid(cutaway) and is_instance_valid(ranged), "cutaway and distance-controlled geometry remains independently controlled")
	check(scenery.get_children().any(func(node: Node) -> bool: return node is MeshInstance3D and node.layers == 2), "baked views preserve camera cull layers")
	var named := MeadowGeometry.box(scenery, Vector3.ZERO, Vector3.ONE, Color.WHITE)
	named.name = "ReferencedRoof"
	StaticDecorationBatch.build(scenery)
	check(is_instance_valid(named) and named.mesh != null, "named presentation references retain their original mesh")
	_scaled_mesh(Vector3(3, 0.35, 1.7))
	_scaled_mesh(Vector3(-3, 0.35, 1.7))
	scenery.queue_free()
	await process_frame
	print("Scenery batching: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

func _scaled_mesh(scale: Vector3) -> void:
	var scenery := Node3D.new()
	root.add_child(scenery)
	var view := MeshInstance3D.new()
	var source := SphereMesh.new()
	source.radial_segments = 8
	source.rings = 4
	source.material = MeadowGeometry.material(Color.RED)
	view.mesh = source
	view.rotation = Vector3(0.2, 0.4, 0.1)
	view.scale = scale
	scenery.add_child(view)
	var pose := view.transform
	var before := source.surface_get_arrays(0)
	StaticDecorationBatch.build(scenery)
	var batch := scenery.get_child(0) as MeshInstance3D
	var after := batch.mesh.surface_get_arrays(0)
	var ink: PackedFloat32Array = after[Mesh.ARRAY_CUSTOM0]
	for i in before[Mesh.ARRAY_INDEX].size():
		var source_corner: int = (i / 3) * 3 + 2 - i % 3 if scale.x < 0 else i
		var old: int = before[Mesh.ARRAY_INDEX][source_corner]
		var baked: int = after[Mesh.ARRAY_INDEX][i]
		check((batch.transform * after[Mesh.ARRAY_VERTEX][baked]).is_equal_approx(pose * before[Mesh.ARRAY_VERTEX][old]), "scaled and mirrored rocks retain authored vertices and winding")
		var normal: Vector3 = before[Mesh.ARRAY_NORMAL][old]
		var expected := (pose.basis.inverse().transposed() * normal).normalized()
		check(after[Mesh.ARRAY_NORMAL][baked].distance_to(expected) < 0.001, "scaled rock lighting retains its inverse-transpose normal")
		var offset := Vector3(ink[baked * 4], ink[baked * 4 + 1], ink[baked * 4 + 2])
		check(offset.is_equal_approx(pose.basis * normal), "scaled rock ink retains the original extrusion direction and width")
		check(after[Mesh.ARRAY_TEX_UV][baked].distance_to(before[Mesh.ARRAY_TEX_UV][old]) < 0.001, "baking retains authored texture coordinates")
	check(batch.mesh.surface_get_material(0).next_pass.shader == DecorationMeshBake.BAKED_INK, "baked ink uses its preserved extrusion channel")
	scenery.queue_free()
