extends SceneTree
## Actual physics/render QA: charge, rise, fall and ground-contact landing.

class JumpInput extends PlayerCommandSource:
	var held: bool = false
	var pressed: bool = false
	func sample(_position: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.aim = Vector2.DOWN
		command.jump_held = held
		command.jump_pressed = pressed
		pressed = false
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var player: Player = scene.get_node("Player")
	var source := JumpInput.new()
	player.add_child(source)
	player.command_source = source
	root.add_child(scene)
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
	scene.camera.offset = Vector3(0, 6, 6)
	scene.hud.toggle_help()
	await ticks(40)
	source.held = true
	source.pressed = true
	await ticks(45)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-jump-charge.png")
	assert(player.is_on_floor() and player.motor.jump_charge == 1.0)
	source.held = false
	var seen: Array[int] = []
	var peak := 0.0
	for tick in 110:
		await ticks(1)
		peak = maxf(peak, player.position.y)
		var frame := player.visuals.jump_animation.frame
		if frame >= 0 and frame not in seen:
			seen.append(frame)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-jump-%02d.png" % (frame + 1))
	assert(player.is_on_floor())
	assert(seen.size() == 10, "Real jump must display all ten provided phases")
	print("Rendered jump phases: ", seen, "; peak: ", peak)
	scene.queue_free()
	await process_frame
	quit()

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame
