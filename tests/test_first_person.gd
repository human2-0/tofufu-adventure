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
	check(command.aim.x < -0.9, "mouse look updates aim without firing")
	Input.action_press("move_up")
	command = source.sample(game.player.position)
	check(command.move.x < -0.9, "movement is camera relative")
	Input.action_release("move_up")
	for slot in [1, 2, 3, 4]:
		game.combat.equipment.step(Vector2.UP, false, false, false, false, slot, 0.016)
		await process_frame
		check(view.weapon_view.visible, "weapon overlay available for slot %d" % slot)
	source.chat_blocked = true
	await process_frame
	await process_frame
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "chat releases pointer")
	source.chat_blocked = false
	view.cycle_mode()
	check(not view.shoulder and not view.first_person and not source.first_person_view, "third cycle returns overhead")
	check(game.player.visuals.layers == original_layers, "body layers restored")
	await process_frame
	await process_frame
	check(not view.weapon_view.visible, "overlay hidden outside first person")
	game.queue_free()
	await process_frame
	if failures == 0: print("First-person checks passed")
	quit(1 if failures else 0)
