extends SceneTree
var failures: int = 0

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var game := load("res://game/app/main.tscn").instantiate() as Node3D
	game.play_opening = false
	root.add_child(game)
	await process_frame
	var view: ShootingView = game.shooting_view
	var source := game.player.command_source as LocalPlayerInput
	var original_layers: int = game.player.visuals.layers
	view.cycle_mode()
	check(view.shoulder and not view.first_person, "first cycle enters shoulder")
	view.cycle_mode()
	check(view.first_person and game.camera.first_person, "second cycle enters first person")
	check(game.player.visuals.layers == 0, "local body hidden")
	game.camera.yaw = PI * 0.5
	game.camera.pitch = -0.3
	game.camera._follow_first_person(1.0)
	check(game.camera.position.distance_to(game.player.position + Vector3.UP * 0.95) < 0.001, "eye follows actor without lag")
	var command := source.sample(game.player.position)
	check(command.aim.x < -0.9 and command.face_aim, "mouse look updates and locks aim without firing")
	Input.action_press("move_up")
	command = source.sample(game.player.position)
	check(command.move.x < -0.9, "movement is camera relative")
	Input.action_release("move_up")
	for slot in [1, 2]:
		game.combat.equipment.step(Vector2.UP, false, false, false, false, slot, 0.016)
		await process_frame
		check(view.weapon_view.visible, "weapon overlay available for slot %d" % slot)
	for jet in [false, true]:
		for ads in [false, true]:
			game.combat.gun.aiming = ads
			game.combat.sotjet.aiming = ads
			view.weapon_view._process(1.0)
			game.camera.fov = 42.0 if ads else 70.0
			var overlay := view.weapon_view
			var sprite: Sprite3D = overlay._jet if jet else overlay._gun
			var cell := Vector2(SotjetVisual.ATLAS.get_size()) / Vector2(5, 2) if jet else SoyGunVisual.REAR_REGIONS[0].size
			var uv := SotjetVisual.MUZZLES[5] if jet else Vector2(0.5, 0.48)
			var landmark := sprite.to_global(Vector3((uv.x - 0.5) * cell.x, (0.5 - uv.y) * cell.y, 0) * sprite.pixel_size)
			var expected := overlay._viewport.get_camera_3d().unproject_position(landmark) / Vector2(overlay._viewport.size)
			var muzzle: Vector3 = view._jet_muzzle() if jet else view._gun_muzzle()
			var actual: Vector2 = game.camera.unproject_position(muzzle) / root.get_visible_rect().size
			check(actual.distance_to(expected) < 0.001, "first-person muzzle matches visible barrel through ADS and camera rotation")
	source.chat_blocked = true
	await process_frame
	await process_frame
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "chat releases pointer")
	source.chat_blocked = false
	view.cycle_mode()
	check(not view.shoulder and not view.first_person and not source.first_person_view, "third cycle returns overhead")
	check(game.player.visuals.layers == original_layers, "body layers restored")
	check(not source.sample(game.player.position).face_aim, "overhead releases first-person facing lock")
	await process_frame
	await process_frame
	check(not view.weapon_view.visible, "overlay hidden outside first person")
	game.queue_free()
	await process_frame
	if failures == 0: print("First-person checks passed")
	quit(1 if failures else 0)
