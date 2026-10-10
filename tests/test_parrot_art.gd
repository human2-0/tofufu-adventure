extends SceneTree
## Shared textured geometry and continuous heading/wing presentation without physics.
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var bird := ParrotArt.new()
	root.add_child(bird)
	bird.set_process(false)
	var meshes := bird.find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 4, "detailed body, two wings and tail use four draws")
	for node: MeshInstance3D in meshes:
		var material := node.mesh.surface_get_material(0) as ShaderMaterial
		check(material != null and material.get_shader_parameter("feather_texture") is Texture2D, "every surface maps the imported feather texture")
	check(meshes[1].mesh == meshes[2].mesh and meshes[1].mesh == ParrotPlumage.wing(), "both wings and every bird reuse one immutable wing mesh")
	bird.airborne = true
	bird.heading = Vector3.RIGHT * 24
	bird._process(1.0 / 144.0)
	check(absf(bird.rotation.y) > 0 and absf(bird.rotation.y) < 0.2, "heading changes progressively on render frames")
	var before := bird.rotation.y
	bird.heading = Vector3.ZERO
	bird._process(1.0 / 144.0)
	check(is_equal_approx(before, bird.rotation.y), "hover keeps its last heading rather than flickering")
	check(is_equal_approx(bird.wings[0].rotation.z, -bird.wings[1].rotation.z), "wings flap symmetrically through mirrored geometry")
	var flap := bird.wings[0].rotation.z
	bird.airborne = false
	bird._process(1.0 / 144.0)
	check(absf(bird.wings[0].rotation.z - flap) < 0.25, "landing blends into the folded-wing pose")
	bird.queue_free()
	await process_frame
	print("Parrot art: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
