extends SceneTree
## Real floor contacts must wake for motion, forces or changed/removed support.
var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func run() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.set_meta("permanent_terrain", true)
	root.add_child(floor_body)
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(20, 0.2, 20)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	var body := CharacterBody3D.new()
	body.position.y = 0.7
	body.collision_layer = 2
	body.collision_mask = 1
	root.add_child(body)
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.0
	capsule.radius = 0.4
	collider.shape = capsule
	body.add_child(collider)
	var rest := MobRest.new()
	for tick in 30:
		await physics_frame
		body.velocity = Vector3.DOWN * 2
		body.move_and_slide()
		rest.remember(body)
	check(rest.can_rest(body, Vector3.ZERO, Vector3.ZERO), "stationary body reuses a confirmed permanent floor contact")
	check(not rest.can_rest(body, Vector3.RIGHT, Vector3.ZERO), "movement intent wakes the body immediately")
	check(not rest.can_rest(body, Vector3.ZERO, Vector3.RIGHT), "knockback wakes the body immediately")
	body.velocity.y = 1.0
	check(not rest.can_rest(body, Vector3.ZERO, Vector3.ZERO), "vertical motion cannot sleep")
	body.velocity.y = 0.0
	floor_shape.shape = BoxShape3D.new()
	check(not rest.can_rest(body, Vector3.ZERO, Vector3.ZERO), "replacing floor geometry invalidates resting contact")
	floor_shape.shape = floor_box
	floor_shape.set_deferred("disabled", true)
	await process_frame
	check(not rest.can_rest(body, Vector3.ZERO, Vector3.ZERO), "disabled floors invalidate resting contact")
	floor_shape.set_deferred("disabled", false)
	await process_frame
	floor_body.position.y += 0.1
	check(not rest.can_rest(body, Vector3.ZERO, Vector3.ZERO), "moving the support invalidates resting contact")
	floor_body.queue_free()
	await process_frame
	check(not rest.can_rest(body, Vector3.ZERO, Vector3.ZERO), "freed support never retains a stale contact")
	body.queue_free()
	await process_frame
	print("Mob rest: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
