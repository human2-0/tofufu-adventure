extends SceneTree
## Actual Godot renders: overhead, shoulder ADS, and a full orbit of billboard art.
var game: Node3D
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1440, 900)
	game = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.player.position = game.world.ground_point(19.3, 14.3) + Vector3.UP * 0.05
	game.combat.equipment.step(Vector2.UP, false, false, false, false, 3, 0.016)
	game.combat.gun.visual.visible = true
	game.camera.global_position = game.player.position + game.camera.offset
	await _pose(Vector2.UP, "overhead")
	game.shooting_view.shoulder = true
	game.camera.set_shoulder(true)
	await _pose(Vector2.UP, "shoulder")
	game.combat.gun.aiming = true
	await _pose(Vector2.UP, "aim")
	game.combat.gun.aiming = false
	for index in 8:
		game.camera.yaw = index * TAU / 8
		await _pose(Vector2.UP, "orbit_%d" % index)
	var source := game.player.command_source as LocalPlayerInput
	source._aim = Vector2.UP
	source._shot_direction = Vector3.FORWARD
	game.camera.yaw = PI * 0.5
	game.camera._follow_shoulder(0.016)
	var free_look := source.sample(game.player.position)
	await _pose(free_look.aim, "free_orbit")
	Input.action_press("attack")
	var hip := source.sample(game.player.position)
	await _pose(hip.aim, "hip_focus")
	Input.action_release("attack")
	Input.action_press("guard")
	var focused := source.sample(game.player.position)
	game.combat.gun.aiming = true
	await _pose(focused.aim, "rmb_focus")
	Input.action_release("guard")
	game.combat.gun.aiming = false
	game.camera.yaw += PI * 0.5
	var retained := source.sample(game.player.position)
	await _pose(retained.aim, "released_orbit")
	game.queue_free()
	await process_frame
	quit()

func _pose(aim: Vector2, title: String) -> void:
	var command := PlayerCommand.new()
	command.aim = aim
	game.combat.gun.visual.facing = aim
	for index in 12:
		game.player.visuals.present(command, Vector3.ZERO, true, false, 0.016)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-gun-%s.png" % title)
