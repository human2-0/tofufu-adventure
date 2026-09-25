extends SceneTree
## Shared water profile, real collision, biome seams and bounded cosmetic fish.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var world: Meadow = load("res://game/world/meadow.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame
	var previous := RiverCourse.level(RiverCourse.START)
	for z in range(-84, 157):
		var level := RiverCourse.level(z)
		check(level <= previous + 0.00001, "water always travels downhill or level")
		previous = level
		var at := RiverCourse.point(z)
		var bed := world.ground_point(at.x, at.z)
		check(bed.y < level - 0.32, "channel stays below surface at %s" % z)
		check(world.is_water(bed), "wading agrees with visible river at %s" % z)
		check(not world.is_water(at + Vector3.UP), "jumping above water is dry")
	for x in range(-60, 30):
		check(is_equal_approx(world.terrain.height_at(x, 84), world.desert.point(x, 84).y), "farm/desert seam is continuous")
	var space := world.get_world_3d().direct_space_state
	for z in [65.0, 84.0, 103.0, 127.0, 148.0, 156.0]:
		var at := RiverCourse.point(z)
		var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 4.0, 1)
		var hit := space.intersect_ray(ray)
		check(not hit.is_empty(), "extended water has solid collision bed")
		if not hit.is_empty(): check(hit.position.y < at.y - 0.25, "collision stays below water")
	check(not world.is_water(Vector3(11, -5, 210)), "old infinite stream cannot mark dry desert as water")
	check(world.is_water(Vector3(-38, -2.5, 148)), "actual oasis position is wet")
	for i in RiverWildlife.COUNT:
		for tick in 160:
			var at := RiverWildlife.swim_position(i, tick * 0.43)
			check(RiverCourse.bank_distance(at.x, at.z) < -0.15, "fish stays within stream or pond")
	var jump := RiverWildlife.swim_position(0, RiverWildlife.JUMP_SECONDS * 0.5)
	check(jump.y > RiverCourse.level(jump.z) + 0.5, "fish clears the surface during a jump")
	var swimming := RiverWildlife.swim_position(0, 3.0)
	check(swimming.y < RiverCourse.level(swimming.z), "fish returns underwater")
	var life: RiverWildlife = world.get_node("RiverWildlife")
	life.present(RiverWildlife.JUMP_SECONDS + 0.2)
	check(life.ripples[0].visible, "landing produces a pooled splash ring")
	check(life.get_child_count() == RiverWildlife.COUNT * 2, "wildlife allocation stays bounded")
	await _cross_bank(world, 110.0)
	await _cross_bank(world, 148.0)
	world.queue_free()
	await process_frame
	print("River continuity, collision, oasis and wildlife: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _cross_bank(world: Meadow, z: float) -> void:
	var body := CharacterBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	body.floor_snap_length = 0.3
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	collider.shape = capsule
	collider.position.y = 0.6
	body.add_child(collider)
	world.add_child(body)
	body.position = world.ground_point(RiverCourse.center_x(z), z, 0.1)
	for frame in 300:
		await physics_frame
		body.velocity.x = 5.0
		body.velocity.y -= 20.0 / 60.0
		body.move_and_slide()
	check(body.position.x > RiverCourse.center_x(z) + RiverCourse.half_width(z) + 3.0, "capsule can walk out of the bank at %s" % z)
	check(body.is_on_floor(), "bank traversal retains solid ground")
	body.queue_free()
