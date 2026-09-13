extends SceneTree

var failures: int = 0
var stage: Node3D
var actor: Node3D
var combat: PlayerCombat

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	actor = Node3D.new()
	stage.add_child(actor)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	await _eight_blade_boundaries()
	await _moving_sweep()
	await _slash_crosses_front()
	_body_clearance()
	_facing_and_camera()
	_hand_attachment()
	stage.queue_free()
	await process_frame
	print("Sword geometry, eight-way sprites and camera: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _eight_blade_boundaries() -> void:
	var tuning := combat.tuning
	for index in 8:
		var aim := Vector2.from_angle(-index * PI / 4)
		var forward := Vector3(aim.x, 0, aim.y)
		var side := Vector3(-aim.y, 0, aim.x)
		var pose := SwordGeometry.pose(Vector3.ZERO, aim, 0.5, tuning)
		forward = -pose.basis.z
		side = pose.basis.x
		var tip := SwordGeometry.tip(pose, tuning)
		var guard := pose.origin
		var center := (tip + guard) * 0.5
		check(SwordGeometry.direction_index(aim) == index, "sword atlas direction %d" % index)
		check(combat.sword.calibrated_vertex(SwordVisual.GUARDS[index], index).length() < 0.001, "visible guard is physical blade base")
		check(combat.sword.calibrated_vertex(SwordVisual.TIPS[index], index).distance_to(Vector3.FORWARD * tuning.blade_length) < 0.001, "visible tip is physical blade endpoint")
		var edge := _target(tip + forward * 0.08)
		var beyond := _target(tip + forward * 0.14)
		var lateral := _target(center + side * (tuning.blade_width * 0.5 + 0.14))
		var overhead := _target(center + pose.basis.y * (tuning.blade_thickness * 0.5 + 0.14))
		var behind := _target(Vector3.UP * tuning.hand_height - forward * 0.8)
		await ticks(2)
		combat.strike(aim, 0.0)
		check(edge.current == 100, "wind-up does not damage targets")
		combat._resolve_blade(Vector3.ZERO, pose)
		check(edge.current == 80, "blade tip touches target's actual collider in direction %d" % index)
		check(beyond.current == 100, "no damage past visible tip in direction %d" % index)
		check(lateral.current == 100 and overhead.current == 100 and behind.current == 100, "blade width, height and rear bounds are respected")
		combat._resolve_blade(Vector3.ZERO, pose)
		check(edge.current == 80, "each target is hit only once per attack")
		combat.reset()
		for target in combat.targets:
			target.body.queue_free()
		combat.targets.clear()
		await ticks(2)

func _moving_sweep() -> void:
	var center := SwordGeometry.blade_transform(SwordGeometry.pose(Vector3.ZERO, Vector2.UP, 0.5, combat.tuning), combat.tuning).origin
	var target := _target(center + Vector3.RIGHT * 0.6)
	await ticks(2)
	combat.strike(Vector2.UP, 0.0)
	check(target.current == 100, "target starts outside stationary blade")
	combat._previous_progress = 0.48
	combat._elapsed = combat.tuning.swing_seconds * 0.48
	actor.position.x = 1.2
	combat.step(Vector2.UP, false, 0.01)
	check(target.current == 80, "blade sweeps between ticks instead of tunneling during a dash")
	combat.reset()

func _slash_crosses_front() -> void:
	actor.position = Vector3.ZERO
	combat.reset()
	var early_pose := SwordGeometry.pose(Vector3.ZERO, Vector2.DOWN, 0.35, combat.tuning)
	var late_pose := SwordGeometry.pose(Vector3.ZERO, Vector2.DOWN, 0.65, combat.tuning)
	var early := _target(SwordGeometry.blade_transform(early_pose, combat.tuning).origin)
	var late := _target(SwordGeometry.blade_transform(late_pose, combat.tuning).origin)
	await ticks(2)
	combat.strike(Vector2.DOWN, 0.0)
	for tick in 4:
		combat.step(Vector2.DOWN, false, 1.0 / 60.0)
	check(early.current == 100 and late.current == 100, "wind-up is harmless")
	for tick in 24:
		combat.step(Vector2.DOWN, false, 1.0 / 60.0)
	check(early.current == 80 and late.current == 80, "slash cuts across both sides of the forward arc exactly once")
	check(not combat.active, "slash completes recovery")

func _body_clearance() -> void:
	var tuning := combat.tuning
	for index in 8:
		var aim := Vector2.from_angle(index * PI / 4)
		for sample in range(-1, 51):
			var pose := SwordGeometry.pose(Vector3.ZERO, aim, sample / 50.0, tuning, true)
			var transform := SwordGeometry.blade_transform(pose, tuning)
			for x in [-1.0, 1.0]:
				for y in [-1.0, 1.0]:
					for z in [-1.0, 1.0]:
						var corner := transform * (Vector3(x, y, z) * combat._shape.size * 0.5)
						check(Vector2(corner.x, corner.z).length() > 0.4, "steel remains outside Fufu's body throughout swing")

func _facing_and_camera() -> void:
	var sprite := FufuVisuals.new()
	stage.add_child(sprite)
	var command := PlayerCommand.new()
	for index in [1, 3, 5, 7]:
		command.move = Vector2.from_angle(index * PI / 4)
		command.aim = Vector2.DOWN
		sprite.present(command, Vector3.ONE, true, false, 0.12)
		check(int(sprite.current_facing) == index, "diagonal travel selects diagonal facing")
		check(sprite.texture == sprite.diagonal_texture and sprite.vframes == 4, "shared sheet is used for all diagonals")
	command.move = Vector2.ZERO
	for index in 8:
		command.aim = Vector2.from_angle(index * PI / 4)
		sprite.present(command, Vector3.ZERO, true, false, 0.2)
		check(sprite.texture == sprite.idle_texture, "all stationary angles use supplied idle art")
		check(sprite.frame == FufuVisuals.IDLE_FRAMES[index] and sprite.vframes == 2, "correct eight-way idle pose")
		check(sprite.flip_h == (index == 7), "only NE idle mirrors NW")
	check(FufuVisuals.IDLE_FRAMES[7] == FufuVisuals.IDLE_FRAMES[5], "NE uses the actual NW pose")
	command.attack_held = true
	command.aim = Vector2.UP
	sprite.present(command, Vector3.ONE, true, false, 0.01)
	check(sprite.current_facing == FufuVisuals.Facing.UP, "attacking preserves mouse aim over travel facing")
	var camera := CameraFollow.new()
	camera.target = actor
	stage.add_child(camera)
	check(absf(camera.rotation_degrees.x + 45.0) < 0.01, "camera starts at 45 degrees")
	actor.position.y += 8.0
	camera._physics_process(1.0 / 60.0)
	check(absf(camera.rotation_degrees.x + 45.0) < 0.01, "camera tilt stays at 45 degrees during a jump")

func _hand_attachment() -> void:
	var sprite := FufuVisuals.new()
	stage.add_child(sprite)
	sprite.hand_presented.connect(combat.sword.follow_hand)
	var command := PlayerCommand.new()
	for index in 8:
		command.aim = Vector2.from_angle(-index * PI / 4)
		for sample in 5:
			command.move = Vector2.ZERO if sample == 0 else command.aim
			sprite.anim_timer = sample - 1
			sprite.scale = Vector3(0.85, 1.2, 0.85)
			sprite.position.y = 2.0
			sprite.present(command, Vector3.ONE, true, false, 0.0)
			var pose := SwordGeometry.pose(Vector3.ZERO, command.aim, -1, combat.tuning)
			combat.sword.present(pose, command.aim, 0, false, 1.0)
			var grip := combat.sword._sprite.global_transform * combat.sword.calibrated_vertex(SwordVisual.GRIPS[index], index)
			var difference := grip - combat.sword._hand
			check(absf(difference.dot(combat.sword._hand_plane.x)) < 0.001 and absf(difference.dot(combat.sword._hand_plane.y)) < 0.001, "grip follows animated/scaled hand in camera plane")
			var depth := difference.dot(combat.sword._hand_plane.z)
			check(depth > 0.03 if index >= 5 else depth < -0.03, "front-facing knife overlaps hand/body; rear-facing body masks the knife")
			combat.sword.present(pose, command.aim, 0, true, 1.0)
			check(combat.sword._sprite.global_transform.is_equal_approx(pose), "active cutting art stays aligned with physical blade even with attachment requested")
	command.move = Vector2.ZERO
	command.aim = Vector2(-1, -1)
	sprite.present(command, Vector3.ZERO, true, false, 0.0)
	var left := combat.sword._hand - sprite.global_position
	command.aim.x = 1
	sprite.present(command, Vector3.ZERO, true, false, 0.0)
	var right := combat.sword._hand - sprite.global_position
	var plane := combat.sword._hand_plane
	check(absf(left.dot(plane.x) + right.dot(plane.x)) < 0.001, "NE hand position mirrors NW about the centered body")
	check(absf(left.dot(plane.y) - right.dot(plane.y)) < 0.001, "mirrored idle hand retains height")
	sprite.queue_free()

func _target(at: Vector3) -> Damageable:
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = at
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.1
	collider.shape = sphere
	body.add_child(collider)
	stage.add_child(body)
	var target := Damageable.new()
	target.maximum = 100
	target.body = body
	body.add_child(target)
	combat.targets.append(target)
	return target

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame
