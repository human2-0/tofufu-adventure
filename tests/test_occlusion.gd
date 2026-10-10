extends SceneTree
## Occlusion is presentation only, follows cutaways, and never seals floor holes.
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var architecture := Node3D.new()
	root.add_child(architecture)
	var wall := MeadowGeometry.box(architecture, Vector3(5, 2, 0), Vector3(8, 4, 0.6), Color.WHITE, true)
	var body := wall.get_child(0) as StaticBody3D
	var collision := (body.get_child(0) as CollisionShape3D).shape
	SolidOcclusion.box(wall)
	var blocker := wall.get_node("SolidOcclusion") as OccluderInstance3D
	check((blocker.occluder as BoxOccluder3D).size.is_equal_approx(Vector3(8, 4, 0.6) * 0.98), "architecture occluders stay strictly inside the visible wall")
	SolidOcclusion.box(wall)
	check(wall.get_child_count() == 2, "repeated setup cannot duplicate occluders")
	wall.hide()
	check(not blocker.is_visible_in_tree(), "hidden cutaway walls stop occluding")
	wall.show()
	wall.scale.y = 0.14
	check(is_equal_approx(blocker.global_basis.get_scale().y, 0.14), "occluders follow shortened maze cutaways")
	check((body.get_child(0) as CollisionShape3D).shape == collision, "occlusion never replaces physical shapes")
	var trim := MeadowGeometry.box(architecture, Vector3.ZERO, Vector3.ONE, Color.WHITE)
	SolidOcclusion.box(trim)
	check(not trim.has_node("SolidOcclusion"), "tiny ornaments add no CPU occluder")
	var ranged := MeadowGeometry.box(architecture, Vector3.ZERO, Vector3(10, 4, 1), Color.WHITE)
	ranged.visibility_range_begin = 22
	SolidOcclusion.box(ranged)
	check(not ranged.has_node("SolidOcclusion"), "distance-controlled roofs cannot create invisible occlusion")
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.BACK, Vector3(48, 2, 0), Vector3(49, 2, 0), Vector3(48, 2, 1)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 3, 4, 5])
	var ground := MeshInstance3D.new()
	ground.mesh = ArrayMesh.new()
	ground.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	root.add_child(ground)
	var mesh := ground.mesh
	var cover := GroundOcclusion.build(ground)
	cover.set_process(false)
	check(cover._tiles.size() == 2, "separate ground tiles retain independent visibility")
	check(ground.mesh == mesh, "ground occlusion leaves the rendered mesh intact")
	cover.present(Vector3(0, 3, 0))
	check(cover._tiles.all(func(tile: OccluderInstance3D) -> bool: return tile.visible), "camera above the entire tile enables its opaque surface")
	cover.present(Vector3(0, 1, 0))
	check(cover._tiles[0].visible and not cover._tiles[1].visible, "only ground entirely below the camera can occlude")
	cover.present(Vector3(0, -1, 0))
	check(not cover._tiles.any(func(tile: OccluderInstance3D) -> bool: return tile.visible), "one-sided ground cannot hide the sky when viewed from below")
	var vertices := PackedVector3Array()
	for tile in cover._tiles: vertices.append_array((tile.occluder as ArrayOccluder3D).vertices)
	check(vertices.size() == 6, "ground retains exact boundary triangles and leaves holes open")
	for i in vertices.size(): check(vertices[i].is_equal_approx(arrays[Mesh.ARRAY_VERTEX][i] - Vector3.UP * GroundOcclusion.INSET), "ground occluder vertices have only a conservative downward inset")
	for child in root.get_children(): child.queue_free()
	await process_frame
	print("Occlusion contracts: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)
