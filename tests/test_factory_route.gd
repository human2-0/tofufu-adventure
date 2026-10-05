extends SceneTree
## Walk the authored switchback and ramp using the real player capsule and motor.
class RouteInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	var jump: bool = false
	var jump_held: bool = false
	var dash: bool = false
	var dash_held: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.jump_pressed = jump
		command.jump_held = jump_held
		command.dash_pressed = dash
		command.dash_held = dash_held
		command.dash_direction = move
		jump = false
		dash = false
		return command

var failures: int = 0
var actor: Player
var source := RouteInput.new()

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	push_error(message)

func ray_hits(start: Vector3, finish: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(start, finish, 1)
	return not actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func walk_to(at: Vector3) -> void:
	for tick in 500:
		var offset := Vector2(at.x - actor.position.x, at.z - actor.position.z)
		var speed := Vector2(actor.velocity.x, actor.velocity.z).length()
		if offset.length() < 0.12 and speed < 0.5: break
		# The real motor carries momentum; approach slowly enough to brake at corners.
		source.move = (offset * 2.0).limit_length()
		await physics_frame
	source.move = Vector2.ZERO
	if actor.position.distance_to(at) > 0.8:
		failures += 1
		push_error("Route blocked at %s, target %s" % [actor.position, at])

func run() -> void:
	var factory := TofuFactory.new()
	root.add_child(factory)
	factory.ensure_interior()
	factory.reset_gates(6)
	actor = load("res://game/player/player.tscn").instantiate()
	actor.add_child(source)
	actor.command_source = source
	actor.position = Vector3(300,0.1,-176)
	root.add_child(actor)
	await physics_frame
	for at in [Vector3(308,0,-180),Vector3(314,0,-180),Vector3(322,0,-176),Vector3(331,0,-180),Vector3(335,0,-180),Vector3(335,0,-176),Vector3(350,0,-176),Vector3(356,0,-176),Vector3(356,4,-208),Vector3(350,4,-210),Vector3(335,4,-210),Vector3(335,4,-206),Vector3(330,4,-206),Vector3(322,4,-210),Vector3(313,4,-210),Vector3(313,4,-206),Vector3(308,4,-206),Vector3(308,4,-212),Vector3(300,4,-212)]:
		await walk_to(at)
	check(TofuFactory.room_at(Vector3(300, 0.2, -180)) == 0, "Ground deck room missing")
	check(TofuFactory.room_at(Vector3(300, 4.2, -206)) == 5, "Upper deck room missing")
	check(not TofuFactory.contains(Vector3(300, 12, -180)), "Above roof classified as legal")
	check(not TofuFactory.contains(Vector3(324, 0, -193)), "Interdeck void classified as legal")
	check(not TofuFactory.permitted_transition(0, 1, 0), "Locked room transition accepted")
	check(TofuFactory.permitted_transition(0, 1, 1), "Cleared room transition rejected")
	check(not TofuFactory.permitted_transition(1, 3, 6), "Nonadjacent room transition accepted")
	check(not TofuFactory.permitted_transition(2, 3, 2), "Locked ramp transition accepted")
	check(TofuFactory.permitted_transition(2, 6, 3), "Cleared ramp transition rejected")
	check(TofuFactory.legal_ground_anchor(TofuFactory.recovery_anchor(5), 5), "Recovery anchor is not legal")
	var player_shape := actor.get_node("CollisionShape3D") as CollisionShape3D
	check(factory.anchor_has_clearance(actor, player_shape, TofuFactory.recovery_anchor(5), 5), "Recovery capsule is blocked")
	check(not factory.anchor_has_clearance(actor, player_shape, Vector3(289, 4.2, -206), 5), "Wall position accepted as an anchor")
	for cutaway in [true, false]:
		factory.set_cutaway(cutaway)
		await physics_frame
		for segment in [
			[Vector3(307, 1, -171), Vector3(307, 1, -168)],
			[Vector3(307, 1, -215), Vector3(307, 1, -218)],
			[Vector3(290, 1, -180), Vector3(287, 1, -180)],
			[Vector3(358, 1, -180), Vector3(361, 1, -180)],
			[Vector3(307, 5, -215), Vector3(307, 5, -218)],
			[Vector3(307, 5, -171), Vector3(307, 5, -168)],
			[Vector3(290, 5, -206), Vector3(287, 5, -206)],
			[Vector3(358, 5, -206), Vector3(361, 5, -206)],
			[Vector3(300, 9, -206), Vector3(300, 11, -206)],
		]:
			check(ray_hits(segment[0], segment[1]), "Shell seam open: %s cutaway=%s" % [segment, cutaway])
	await attack_perimeter(factory)
	factory.reset_gates(0)
	await physics_frame
	check(ray_hits(Vector3(310, 5, -180), Vector3(312, 5, -180)), "Closed gate can be jumped")
	factory.open_gate(0)
	await physics_frame
	check(not ray_hits(Vector3(310, 5, -180), Vector3(312, 5, -180)), "Opened gate still collides")
	print("Factory physical route: ", "PASS" if failures == 0 else "FAIL")
	for child: Node in root.get_children(): child.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)

func attack_perimeter(factory: TofuFactory) -> void:
	# Repeatable approach coordinates cover both decks, corners, roof and gate seams.
	var segments: Array = [
		[Vector3(291, 0.1, -180), Vector2.LEFT, "ground west"],
		[Vector3(355, 0.1, -176), Vector2.RIGHT, "ground east landing"],
		[Vector3(300, 0.1, -172), Vector2.DOWN, "ground south"],
		[Vector3(291, 4.1, -206), Vector2.LEFT, "upper west"],
		[Vector3(355, 4.1, -208), Vector2.RIGHT, "upper east landing"],
		[Vector3(300, 4.1, -214), Vector2.UP, "upper north"],
		[Vector3(291, 4.1, -214), Vector2(-1, -1).normalized(), "upper northwest seam"],
		[Vector3(355, 0.1, -172), Vector2(1, 1).normalized(), "ground southeast seam"],
	]
	for cutaway in [true, false]:
		factory.set_cutaway(cutaway)
		for segment: Array in segments:
			for ability: String in ["jump", "charged jump", "dash", "super dash", "knockback"]:
				await attack(segment[0], segment[1], ability, "%s cutaway=%s" % [segment[2], cutaway])
	factory.reset_gates(0)
	for cutaway in [true, false]:
		factory.set_cutaway(cutaway)
		for ability: String in ["charged jump", "super dash", "knockback"]:
			await attack(Vector3(308, 0.1, -180), Vector2.RIGHT, ability, "locked sorting door cutaway=%s" % cutaway, 310.7)

func attack(at: Vector3, direction: Vector2, ability: String, label: String, max_x: float = 359.0) -> void:
	source.move = Vector2.ZERO
	source.jump_held = false
	source.dash_held = false
	actor.motor.cancel_jump()
	actor.motor.cancel_dash_charge()
	actor.motor.is_dashing = false
	actor.motor.cooldown_remaining = 0
	actor.velocity = Vector3.ZERO
	actor.relocate(at)
	for settle in 5: await physics_frame
	source.move = direction
	if ability == "jump": source.jump = true
	if ability == "charged jump":
		source.jump = true
		source.jump_held = true
	if ability == "dash" or ability == "super dash":
		source.dash = true
		source.dash_held = ability == "super dash"
	for tick in 95:
		if tick == 42: source.jump_held = false
		if ability == "knockback": actor.apply_push(Vector3(direction.x, 0, direction.y) * 70)
		await physics_frame
		var pos: Vector3 = actor.global_position
		check(pos.x >= 289.05 and pos.x <= max_x and pos.z >= -215.9 and pos.z <= -170.15 and pos.y < 9.5 and pos.y > -0.85, "Capsule escaped %s using %s from %s: %s" % [label, ability, at, pos])
		if pos.x < 289.05 or pos.x > max_x or pos.z < -215.9 or pos.z > -170.15 or pos.y >= 9.5 or pos.y <= -0.85: break
	source.move = Vector2.ZERO
	source.jump_held = false
	source.dash_held = false
