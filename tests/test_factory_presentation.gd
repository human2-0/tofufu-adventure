extends SceneTree
## Snapshot presentation stays aligned with identities, physical props and batch flow.

var failures: int = 0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var factory := TofuFactory.new()
	root.add_child(factory)
	factory.ensure_interior()
	await process_frame
	_floor_regression(factory)
	var snapshot := TofuDungeonAttempt.new().capture()
	var lab: Dictionary = snapshot.lab
	lab.shelf_order = FactoryLayout.CHEMICAL_IDS.duplicate()
	lab.shelf_order.reverse()
	FactoryProductionVisuals.present_factory(factory, snapshot)
	var views: Array[Node] = get_nodes_in_group("factory_production_visuals")
	_check(views.size() == 6, "one presentation adapter per room")
	var sorting: Node3D = views[0].get_parent()
	var laboratory: Node3D = views[1].get_parent()
	_label_regression(sorting, laboratory)
	_check(not (laboratory.get_node("coagulation_tank/MovingParts/MilkLevel") as Node3D).visible, "unproduced milk absent")
	for index in 20:
		var bottle: Node3D = laboratory.get_node("container_%02d" % index)
		_check(bottle.get_meta("content_id") == lab.shelf_order[index], "persisted shelf identity %d" % index)
		_check(not (bottle.get_node("ContentLabel") as Label3D).text.is_empty(), "legible chemical label %d" % index)
	snapshot.sorting.carried_by = {"sack_edamame": 7}
	var actors: Dictionary = {7: Vector3(294, 0.2, -180)}
	FactoryProductionVisuals.present_factory(factory, snapshot, actors)
	_check((sorting.get_node("sack_edamame") as Node3D).global_position.is_equal_approx(actors[7] + Vector3(0, 0.7, 0.6)), "carried sack follows only its owner")
	snapshot.sorting.carried_by = {}
	snapshot.sorting.assignments = {"sack_mature": "intake_tofu"}
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(not (laboratory.get_node("coagulation_tank/MovingParts/MilkLevel") as Node3D).visible, "tank waits for visible transit")
	(sorting.get_node("BatchLine") as FactoryBatchLine)._process(10.0)
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(not (sorting.get_node("sack_mature") as Node3D).visible, "consumed assigned sack absent")
	_check((sorting.get_node("sack_edamame/Body") as StaticBody3D).collision_layer == 0, "carryable sacks cannot form climbing collisions")
	_check((views[0] as FactoryProductionVisuals)._audio._loop.stream != null, "produced batch starts a local machine sound")
	_check((laboratory.get_node("coagulation_tank/MovingParts/MilkLevel") as Node3D).visible, "produced milk reaches tank")
	_check((sorting.get_node("sack_edamame") as Node3D).position.is_equal_approx(Vector3(-6, 0, 5)), "released sack recovers to dock")
	snapshot.cut.completed = true
	snapshot.cut.widths = [0.98, 1.02, 1.0, 1.0, 1.01, 0.99]
	snapshot.pack.slab_slots = [0, -1, -1, -1, -1, -1]
	snapshot.pack.slot_slabs = [0, -1, -1, -1, -1, -1]
	snapshot.pack.sealed = [true, false, false, false, false, false]
	FactoryProductionVisuals.present_factory(factory, snapshot)
	var cutting: Node3D = views[3].get_parent()
	var packing: Node3D = views[4].get_parent()
	_check(not (cutting.get_node("slab_0") as Node3D).visible, "transferred slab absent at dock")
	_check(is_equal_approx((cutting.get_node("slab_1") as Node3D).scale.x, 1.02), "slab mesh follows measured width")
	_check((packing.get_node("package_0/Contents") as Node3D).visible, "packed contents visible")
	_check((packing.get_node("package_0/Seal") as Node3D).visible, "sealed package visible")
	_check(not (packing.get_node("package_1/Seal") as Node3D).visible, "empty package unsealed")
	var motion: Dictionary = {"active_sample": 2, "gauge": 86.0, "elapsed": 6.88}
	FactoryProductionVisuals.present_factory(factory, snapshot, {}, motion)
	var press_audio: FactoryMachineAudio = (views[2] as FactoryProductionVisuals)._audio
	_check(press_audio._loop.playing, "active press loops positional motor sound")
	FactoryProductionVisuals.present_factory(factory, snapshot)
	_check(not press_audio._loop.playing, "idle press stops motor sound")
	factory.queue_free()
	await process_frame
	if failures == 0: print("Factory presentation: PASS")
	quit(1 if failures else 0)

func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _floor_regression(factory: TofuFactory) -> void:
	var surfaces: Array[MeshInstance3D] = []
	for child in factory.get_children():
		if not child is MeshInstance3D: continue
		var mesh: MeshInstance3D = child
		if mesh.has_meta("factory_collision_support"):
			_check(not mesh.visible, "overlapping collision support is invisible")
			_check((mesh.get_child(0) as StaticBody3D).collision_layer == 1, "hidden support keeps physics")
		if mesh.has_meta("factory_floor_surface"):
			surfaces.append(mesh)
			_check((mesh.mesh.surface_get_material(0) as StandardMaterial3D).next_pass == null, "floor surface has no expanded ink backface")
	_check(surfaces.size() == 4, "exactly two deck surfaces and disjoint landing extensions")
	for index in surfaces.size():
		for other in range(index + 1, surfaces.size()):
			if not is_equal_approx(surfaces[index].position.y, surfaces[other].position.y): continue
			var size_a: Vector2 = (surfaces[index].mesh as PlaneMesh).size
			var size_b: Vector2 = (surfaces[other].mesh as PlaneMesh).size
			var center_a := Vector2(surfaces[index].position.x, surfaces[index].position.z)
			var center_b := Vector2(surfaces[other].position.x, surfaces[other].position.z)
			_check(not Rect2(center_a - size_a * 0.5, size_a).intersects(Rect2(center_b - size_b * 0.5, size_b)), "visible coplanar floor surfaces never overlap")
	var ramp: MeshInstance3D = factory.get_node("RampSurface")
	_check((ramp.material_override as StandardMaterial3D).next_pass == null, "ramp does not expand ink into landing")

func _label_regression(sorting: Node3D, laboratory: Node3D) -> void:
	var line: Node3D = sorting.get_node("intake_tofu")
	var title: Label3D = line.get_node("LinePlate")
	var plate: MeshInstance3D = line.get_node("StaticVisual/InspectionPlate")
	_check(title.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "machine plate lettering keeps authored plane")
	_check(title.position.z - plate.position.z - (plate.mesh as BoxMesh).size.z * 0.5 >= 0.025, "machine text clears plate and outline depth")
	for id: String in FactoryLayout.SACK_IDS:
		var sack: Node3D = sorting.get_node(id)
		var tag: MeshInstance3D = sack.get_node("StaticVisual/HarvestTag")
		var label: Label3D = sack.get_node("TagText")
		_check(label.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "sack lettering is fixed to tag")
		_check(label.position.z - tag.position.z - (tag.mesh as BoxMesh).size.z * 0.5 >= 0.025, "sack title stays outside backing plane")
	for index in 20:
		var bottle: Node3D = laboratory.get_node("container_%02d" % index)
		var label: Label3D = bottle.get_node("ContentLabel")
		_check(label.position.y >= 0.6 and label.billboard == BaseMaterial3D.BILLBOARD_DISABLED and not label.double_sided, "bottle caption stays on a single fixed face above cap")
