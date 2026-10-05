extends SceneTree
## Running carry pose and the actual aiming ray share one eased screen offset.
var failures: int = 0
var game: AdventureGame
var view: ShootingView
var source: LocalPlayerInput

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func advance(count: int, delta: float = 1.0 / 60.0) -> void:
	for frame in count:
		view._process(delta)
		view.weapon_view._process(delta)
		game.combat.gun.visual.refresh()
		game.combat.sotjet.visual.refresh()

func projected_aim() -> Vector2:
	var command := source.sample(game.player.position)
	return game.camera.unproject_position(command.aim_point) / root.get_visible_rect().size

func _run() -> void:
	var thirty := GunRunPose.new()
	var sixty := GunRunPose.new()
	for frame in 15: thirty.step(true, 1.0 / 30.0)
	for frame in 30: sixty.step(true, 1.0 / 60.0)
	check(is_equal_approx(thirty.blend, sixty.blend), "carry easing has the same timing at 30 and 60 FPS")
	check(GunRunPose.new().blend == 0.0, "carry pose is isolated per view")
	root.size = Vector2i(1440, 900)
	game = load("res://game/app/adventure/main.tscn").instantiate() as AdventureGame
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.player.position = game.world.ground_point(0, 0)
	game.loadout.select(2)
	view = game.shooting_view
	view.set_process(false)
	view.set_process_unhandled_input(false)
	source = game.player.command_source as LocalPlayerInput
	game.combat.gun.step(false, false, Vector2.UP, Vector3.ZERO, 0.0)
	game.combat.sotjet.step(false, false, Vector2.UP, Vector3.ZERO, 0.0)
	await process_frame
	for mode in ["shoulder", "first-person"]:
		view.cycle_mode()
		game.camera.yaw = 0.0
		game.camera.pitch = 0.12
		if view.first_person: game.camera._follow_first_person(1.0)
		else: game.camera._follow_shoulder(1.0)
		view.run_pose.reset()
		advance(1, 0.0)
		var camera_rotation := game.camera.rotation
		var normal_basis := game.combat.gun.visual.global_basis
		game.player.velocity = Vector3(0, 0, -game.player.tuning.run_speed)
		game.player.motor.endurance.running = true
		advance(1)
		check(view.run_pose.blend > 0.0 and view.run_pose.blend < 0.5, mode + " starts lowering gradually")
		advance(30)
		check(view.run_pose.blend > 0.98, mode + " settles into a running carry pose")
		check(view.reticle.aim_offset.is_equal_approx(source.camera_aim_offset), mode + " aim marker and input use one offset")
		check(projected_aim().distance_to(Vector2(0.5, 0.5) + view.reticle.aim_offset) < 0.001, mode + " actual ray lands on the lowered aim marker")
		check(game.camera.rotation.is_equal_approx(camera_rotation), mode + " lowering leaves mouse-look orientation intact")
		check((game.combat.gun.visual.global_basis * Vector3.FORWARD).y < (normal_basis * Vector3.FORWARD).y, mode + " world gun points further down")
		if view.first_person:
			check(view.weapon_view._rig.rotation.x < -0.23, "first-person gun and hands angle down together")
		Input.action_press("attack")
		var before := view.run_pose.blend
		advance(1)
		check(view.run_pose.blend < before and view.run_pose.blend > 0.0, mode + " firing raises the gun smoothly")
		check(projected_aim().distance_to(Vector2(0.5, 0.5) + view.reticle.aim_offset) < 0.001, mode + " shots still follow the visible marker during recovery")
		Input.action_release("attack")
		advance(30)
		game.player.motor.endurance.running = false
		game.player.velocity = Vector3(0, 0, -game.player.tuning.walk_speed)
		before = view.run_pose.blend
		advance(1)
		check(view.run_pose.blend < before and view.run_pose.blend > 0.0, mode + " walking starts a gradual return")
		advance(90)
		check(view.run_pose.blend == 0.0 and source.camera_aim_offset.is_zero_approx(), mode + " walking restores raised gun and aim")
		var raised_point := source._shooting_point(game.player.position, Vector2.ZERO, true)
		var raised_direction := (raised_point - game.player.position - Vector3.UP * 0.65).normalized()
		check(source._shot_direction.distance_to(raised_direction) < 0.001, mode + " lowered aim never accumulates in the resting direction")
		Input.action_press("attack")
		check(projected_aim().distance_to(Vector2(0.5, 0.5)) < 0.001, mode + " raised shots return to the normal aim marker")
		Input.action_release("attack")
		game.player.velocity = Vector3.ZERO
		advance(2)
		check(view.run_pose.blend == 0.0, mode + " standing keeps the normal pose")
	game.player.velocity = Vector3(0, 0, -game.player.tuning.run_speed)
	Input.action_press("run")
	advance(30)
	check(view.run_pose.blend == 0.0, "holding run without movement intent does not lower the gun on a push")
	Input.action_press("move_up")
	advance(30)
	check(view.run_pose.blend > 0.98, "guest reserve snapshots do not interrupt the local running pose")
	game.player.motor.endurance.exhausted = true
	advance(90)
	check(view.run_pose.blend == 0.0, "exhausted running returns the gun to normal")
	game.player.motor.endurance.reset()
	advance(30)
	game.combat.gun.reload_remaining = 1.0
	game.combat.gun.magazine = 0
	advance(1)
	check(view.run_pose.blend < 0.99 and game.hud._charge_text.text.begins_with("RELOADING"), "reload feedback takes priority over the running pose")
	game.combat.gun.reload_remaining = 0.0
	game.combat.gun.magazine = 9
	game.loadout.select(1)
	advance(1)
	check(view.run_pose.blend == 0.0 and source.camera_aim_offset.is_zero_approx(), "switching to melee clears lowered aiming")
	game.loadout.select(2)
	advance(30)
	var original := game.character_equipment.get_slot("combat_2")
	game.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	game.combat.sotjet.step(false, false, Vector2.UP, Vector3.ZERO, 0.0)
	advance(1, 0.0)
	check(view.weapon_view._jet.visible and view.weapon_view._rig.rotation.x < -0.23, "Soyjet shares the first-person carry pose")
	check((game.combat.sotjet.visual.global_basis * Vector3.FORWARD).y < -0.2, "Soyjet's world barrel angles toward the ground")
	Input.action_press("guard")
	advance(90)
	check(view.run_pose.blend == 0.0, "precise aiming returns the gun to normal while running")
	Input.action_release("guard")
	game.character_equipment.set_slot("combat_2", original)
	game.combat.gun.step(false, false, Vector2.UP, Vector3.ZERO, 0.0)
	game.combat.sotjet.step(false, false, Vector2.UP, Vector3.ZERO, 0.0)
	advance(30)
	view.cycle_mode()
	check(source.camera_aim_offset.is_zero_approx(), "overhead clears the offset before the next input sample")
	Input.action_release("run")
	Input.action_release("move_up")
	game.player.velocity = Vector3.ZERO
	if "--preview" in OS.get_cmdline_user_args(): await preview()
	game.queue_free()
	await process_frame
	await process_frame
	if failures == 0: print("Gun running pose checks passed")
	quit(1 if failures else 0)

func preview() -> void:
	game.hud._notice_time = 0.0
	for mode in ["shoulder", "first-person"]:
		view.cycle_mode()
		game.camera.yaw = 0.0
		game.camera.pitch = 0.12
		if view.first_person: game.camera._follow_first_person(1.0)
		else: game.camera._follow_shoulder(1.0)
		for phase in ["standing", "running", "returning", "walking"]:
			var running: bool = phase == "running"
			game.player.motor.endurance.running = running
			game.player.velocity = Vector3.ZERO if phase == "standing" else Vector3(0, 0, -7.2 if running else -4.8)
			var command := PlayerCommand.new()
			command.aim = Vector2.UP
			command.move = Vector2.UP if phase != "standing" else Vector2.ZERO
			for frame in (4 if phase == "returning" else 60):
				game.player.visuals.present(command, game.player.velocity, true, false, 1.0 / 60.0)
				advance(1)
				await process_frame
			view.reticle.queue_redraw()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-gun-carry-%s-%s.png" % [mode, phase])
