extends SceneTree
## Surface mappings preserve the collision shell and moving quest prop paint.

var failed: bool = false

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	for texture: Texture2D in FactorySurfaceMaterials.SURFACES.values():
		_check(texture.get_image().has_mipmaps(), "3D surface texture supplies mip levels for the anisotropic filter")
	var factory := TofuFactory.new()
	root.add_child(factory)
	factory.ensure_interior()
	for child in factory.get_children():
		if not child is MeshInstance3D: continue
		var visual := child as MeshInstance3D
		if visual.has_meta("factory_collision_support"):
			_check(not visual.visible, "overlapping floor collision keeps its visual hidden")
			_check((visual.get_child(0) as StaticBody3D).collision_layer == 1, "hidden floor keeps capsule collision")
			continue
		if not visual.mesh is BoxMesh and not visual.mesh is PlaneMesh: continue
		var painted: StandardMaterial3D = _material(visual)
		_check(painted != null and painted.albedo_texture != null, "building surface has authored texture")
		_check(painted.uv1_world_triplanar, "world surface paint aligns across independent solids")
		if visual.has_meta("factory_floor_surface"):
			_check(painted.next_pass == null, "floor tile texture never introduces an expanded outline")
			_check(painted.uv1_scale == Vector3.ONE * 0.5, "tile size is consistent on both decks and landing extensions")
	var ramp: MeshInstance3D = factory.get_node("RampSurface")
	_check(_material(ramp).next_pass == null, "ramp remains free of an ink overlap at its flush landings")
	_check((ramp.mesh as BoxMesh).size == Vector3(6, 0.5, 26.37), "texturing preserves real ramp dimensions")
	var sacks: Array[Node] = factory.find_children("sack_*", "Node3D", true, false)
	_check(sacks.size() == 3, "all three authored sack models remain present")
	for sack in sacks:
		var canvas: MeshInstance3D = sack.get_node("StaticVisual/FilledCanvas")
		var painted := _material(canvas)
		_check(painted.albedo_texture.resource_path.ends_with("/linen.svg"), "every sack uses a woven canvas surface")
		_check(not painted.uv1_world_triplanar, "carried canvas paint moves with the sack")
	_procedural_coverage()
	factory.set_cutaway(false)
	for visual in factory._cutaway_meshes:
		_check(visual.visible and (visual.get_child(0) as StaticBody3D).collision_layer == 1, "closed roof and walls stay visible and solid")
		_check(_material(visual).albedo_texture != null, "closed shell has textured surfaces")
	factory.set_cutaway(true)
	for visual in factory._cutaway_meshes:
		_check(not visual.visible and (visual.get_child(0) as StaticBody3D).collision_layer == 1, "camera cutaway preserves the textured shell collision")
	factory.queue_free()
	await process_frame
	await process_frame
	if not failed: print("Factory surface textures: PASS")
	quit(1 if failed else 0)

func _material(visual: MeshInstance3D) -> StandardMaterial3D:
	return (visual.material_override if visual.material_override != null else visual.mesh.surface_get_material(0)) as StandardMaterial3D

func _procedural_coverage() -> void:
	var minimums: Array[int] = [17, 22, 0, 7, 19, 4]
	for view: FactoryProductionVisuals in get_nodes_in_group("factory_production_visuals"):
		var count: int = 0
		for visual: MeshInstance3D in view.get_parent().find_children("*", "MeshInstance3D", true, false):
			if not visual.has_meta("factory_procedural_surface"): continue
			count += 1
			var painted := _material(visual)
			_check(painted.albedo_texture != null, "authored procedural machine, rack, dock or food surface is textured")
			_check(not painted.uv1_world_triplanar, "procedural paint stays attached during cosmetic movement")
			var original := visual.mesh.surface_get_material(0) as StandardMaterial3D
			_check(painted.next_pass == original.next_pass, "procedural texturing preserves the existing ink outline")
		_check(count >= minimums[view.room], "all authored procedural details have surface coverage in room %d" % view.room)

func _check(condition: bool, message: String) -> void:
	if condition: return
	failed = true
	push_error(message)
