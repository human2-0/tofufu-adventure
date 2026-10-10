extends SceneTree
## Geometry/collision preservation and validated local rendering preferences.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [0.0, 48.0]:
		for offset: Vector3 in [Vector3.ZERO, Vector3.RIGHT, Vector3.BACK]:
			surface.set_color(Color.GREEN)
			surface.set_normal(Vector3.UP)
			surface.add_vertex(Vector3(x, 0, 0) + offset)
	var ground := MeshInstance3D.new()
	ground.mesh = surface.commit()
	ground.material_override = StandardMaterial3D.new()
	root.add_child(ground)
	ground.create_trimesh_collision()
	var body := ground.get_child(0) as StaticBody3D
	var shape := body.get_child(0) as CollisionShape3D
	var collision := shape.shape
	TerrainSupport.mark_permanent(ground)
	TerrainChunks.split_visual(ground, true)
	check(ground.mesh == null and ground.get_child_count() == 3, "two separate visual tiles replace one broad mesh")
	check(shape.shape == collision and body.collision_layer == 1, "terrain retains its original physical surface")
	check(body.get_meta("permanent_terrain", false), "physical terrain support remains independent of visual tiling")
	var triangles := 0
	for node in ground.get_children():
		if node is not MeshInstance3D: continue
		var tile := node as MeshInstance3D
		triangles += tile.mesh.surface_get_array_index_len(0) / 3
		check(tile.material_override == ground.material_override, "tile retains the authored material")
		check(tile.mesh.get_aabb().size.x < 2, "each tile has independently bounded geometry")
	check(triangles == 2, "tiling preserves all triangles")
	var ornaments := Node3D.new()
	root.add_child(ornaments)
	MeadowGeometry.box(ornaments, Vector3(1, 2, 3), Vector3(1, 2, 1), Color.GREEN)
	MeadowGeometry.box(ornaments, Vector3(3, 2, 3), Vector3(1, 2, 1), Color.GREEN)
	var solid := MeadowGeometry.box(ornaments, Vector3(2, 0, 3), Vector3(4, 0.5, 4), Color.GREEN, true)
	var physical := solid.get_child(0) as StaticBody3D
	StaticDecorationBatch.build(ornaments)
	check(is_instance_valid(solid) and solid.mesh == null and is_instance_valid(physical) and physical.get_parent() == solid, "ornament batching retains the original collider parent and moves only its rendered geometry into the batch")
	check(ornaments.get_child_count() == 2, "compatible immutable geometry shares one draw beside the untouched collider")
	var baked := ornaments.get_child(1) as MeshInstance3D
	check(baked.mesh.get_aabb().position.is_equal_approx(Vector3(0, -0.25, 1)) and baked.mesh.get_aabb().end.is_equal_approx(Vector3(4, 3, 5)), "batching preserves the exact world extents of ornaments and solid geometry")
	ornaments.queue_free()
	var reef := OceanMaterial.create()
	var coast := OceanMaterial.create(Vector2(128, -64))
	check(reef.shader == coast.shader, "all oceans reuse the same lightweight shader")
	check(not reef.shader.code.contains("hint_screen_texture") and not reef.shader.code.contains("hint_depth_texture"), "ocean rendering never requests a framebuffer copy")
	check(coast.get_shader_parameter("bed_encoding") == Vector2(128, -64), "coastline retains its authored deep seabed range")
	var motion := CameraMotion.new()
	motion.push(Vector3.ZERO)
	motion.push(Vector3(2, 0, 0))
	check(motion.sample(0.5) == Vector3.RIGHT, "camera presents movement between physics ticks")
	motion.push(Vector3(100, 0, 0))
	check(motion.sample(0.5) == Vector3(100, 0, 0), "teleports never smear the camera across the world")
	var replica_motion := ReplicaMotion.new()
	replica_motion.push(Vector3.ZERO, Vector3.RIGHT * 20, 0.0)
	replica_motion.push(Vector3.RIGHT, Vector3.RIGHT * 20, 0.05)
	check(replica_motion.sample(0.1).is_equal_approx(Vector3.RIGHT * 0.5), "remote motion interpolates between received positions")
	replica_motion.push(Vector3.RIGHT * 2, Vector3.RIGHT * 20, 0.11)
	check(replica_motion.sample(0.155).is_equal_approx(Vector3.RIGHT * 1.5), "uneven packet arrivals retain continuous remote motion")
	check(replica_motion.sample(10).is_equal_approx(Vector3.RIGHT * 4), "a stalled remote stream extrapolates for at most 100 ms")
	replica_motion.push(Vector3.RIGHT * 2.01, Vector3.ZERO, 10.0, true)
	check(replica_motion.sample(10) == Vector3.RIGHT * 2.01, "respawns discard previous remote motion even nearby")
	var actor: Player = load("res://game/player/player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	var presentation: ActorPresentation
	for child in actor.get_children():
		if child is ActorPresentation: presentation = child
	actor.position = Vector3.RIGHT * 2
	presentation._physics_process(0.016)
	presentation.present(0.5)
	check(is_equal_approx(actor.visuals.global_position.x, 1) and actor.position.x == 2, "existing character sprite interpolates without moving its physics body")
	check(presentation.ground_position.is_equal_approx(Vector3.RIGHT), "mounts can share the same rendered ground position as their rider")
	actor.relocated.emit()
	check(is_equal_approx(actor.visuals.global_position.x, 2), "character relocations immediately reset visual history")
	check(actor.find_children("*", "Sprite3D", true, false).size() == 1, "walking interpolation retains exactly one character sprite")
	var camera := CameraFollow.new()
	camera.target = actor
	root.add_child(camera)
	camera.set_shoulder(true)
	camera.pitch = 0.0
	var wall := StaticBody3D.new()
	wall.position = Vector3(2, 1, 1.5)
	root.add_child(wall)
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(4, 4, 0.2)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	await physics_frame
	await process_frame
	camera._physics_process(0.016)
	check(camera.position.z < 1.4 and camera.position.z > 0.5, "physics collision sampling retracts the rendered shoulder camera before a wall")
	camera.queue_free()
	wall.queue_free()
	actor.queue_free()
	var changes := ReplicaWorldChanges.new()
	var row := {"values": [1, 2]}
	check(changes.changed("barn", row) and not changes.changed("barn", row), "unchanged co-op views are applied once")
	row.values[0] = 3
	check(changes.changed("barn", row), "comparison records cannot alias mutable received packets")
	check(ReplicaWorldChanges.new().changed("barn", row), "joining a new session starts with no cached world state")
	var budget := ResolutionBudget.new()
	budget.reset(120, 1.0)
	for frame in 1200: budget.sample(0.012)
	check(is_equal_approx(budget.scale, 0.85), "sustained overload stays within the 85 percent quality floor")
	for frame in 7200: budget.sample(1.0 / 120.0)
	check(is_equal_approx(budget.scale, 1.0), "long stable periods restore full resolution")
	budget.sample(5.0)
	check(is_equal_approx(budget.scale, 1.0), "isolated loading stalls cannot reduce resolution")
	budget.reset(120, 0.75)
	for frame in 1200: budget.sample(0.012)
	check(is_equal_approx(budget.scale, 0.75), "adaptive resolution never lowers an explicitly chosen low scale")
	var grid := TerrainGrid.new(Rect2i(0, 0, 2, 2), func(x: float, z: float) -> float: return x + z, 1)
	check(is_equal_approx(grid.interpolated_height(Vector2(0.25, 1.25)), 1.5), "wildlife smoothly samples the cached seabed")
	var prefs := GamePreferences.new()
	prefs.adaptive_resolution = false
	prefs.path = "user://test_render_budget_%d.cfg" % Time.get_ticks_usec()
	prefs.apply_rendering(root, 120, 0.85)
	check(prefs.save() == OK, "frame cap and 3D scale save")
	var restored := GamePreferences.new()
	restored.path = prefs.path
	restored.load_preferences()
	check(restored.frame_limit == 120 and restored.render_scale == 0.85, "rendering preferences survive restart")
	check(not restored.adaptive_resolution, "disabling adaptation survives restart")
	prefs.apply_rendering(root, -1, NAN)
	check(prefs.frame_limit == 120 and prefs.render_scale == 1.0 and Engine.max_fps == 120, "invalid rendering values fall back to the native 120 FPS target")
	DirAccess.remove_absolute(prefs.path)
	ground.queue_free()
	await process_frame
	print("Render budget: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
