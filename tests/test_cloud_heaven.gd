extends SceneTree
## New ornaments have solid bodies; decorative floors and mist preserve navigation.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	var paving := Node3D.new()
	CloudCourtyards.build(paving)
	for floor_view: MeshInstance3D in paving.get_children():
		var normals: PackedVector3Array = floor_view.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		check(normals[0].y > 0.9, "marble paths and mosaics face the walking camera")
	paving.free()
	var realm := CloudRealm.new()
	root.add_child(realm)
	for frame in 3: await physics_frame
	var ground: MeshInstance3D = realm.get_node("WalkableClouds")
	check((ground.material_override as StandardMaterial3D).albedo_texture == CloudMaterials.CLOUD, "real cloud texture covers the walkable floor")
	check(CloudMaterials.marble().uv1_world_triplanar and CloudMaterials.silk().albedo_texture == CloudMaterials.SILK, "marble and embroidered cloth use shared world-scaled textures")
	var mist: CloudMist = realm.get_node("CloudMist")
	check(mist.view.multimesh.instance_count == 42, "cloud wisps stay bounded")
	for i in mist.view.multimesh.instance_count:
		# Dummy rendering does not retain MultiMesh buffers; inspect the submitted layout.
		var at := mist.global_position + mist.poses[i].origin
		check(at.y + 0.7 < CloudTerrain.height_at(at.x, at.z), "mist remains below the walking surface")
	for at: Vector2 in [Vector2(-8, 247), Vector2(-8, 254), Vector2(-8, 277), Vector2(19, 271), Vector2(-22, 272), Vector2(-33, 275), Vector2(-4, 284), Vector2(0, 295), Vector2(42, 288), Vector2(-57, 299), Vector2(6, 333), Vector2(-40, 339), Vector2(46, 333)]:
		var point := CloudTerrain.point(at.x, at.y)
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.9, point - Vector3.UP, 1)
		var hit := realm.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y - point.y) < 0.16, "original landing/paths retain floor clearance at " + str(at))
	for at: Vector2 in [Vector2(-17, 263), Vector2(39, 283), Vector2(5, 336)]:
		var point := CloudTerrain.point(at.x, at.y)
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2, point + Vector3.UP * 0.3, 1)
		var hit := realm.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty(), "new amphorae and offering table have real collisions")
	check(realm.court.residents.size() == 12 and realm.court.angels.size() == 12, "batching preserves the court and angel population")
	for mote in realm.motes: check(is_instance_valid(mote) and mote.mesh != null, "batching preserves animated celestial motes")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.make_current()
	var roofs := realm.find_children("*", "CloudRoof", true, false)
	check(roofs.size() == 2, "both temple roofs keep complete cutaway groups")
	for roof: CloudRoof in roofs:
		camera.global_position = roof.global_position + Vector3.UP * 10
		roof._process(0)
		check(not roof.visible, "near cameras reveal the court without detached roof details")
		camera.global_position = roof.global_position + Vector3.UP * 30
		roof._process(0)
		check(roof.visible, "distant cameras show the complete temple roof")
	camera.free()
	realm.free()
	print("Cloud heaven: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
