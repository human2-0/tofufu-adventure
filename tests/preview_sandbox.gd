extends SceneTree
## Optional renderer QA: saves actual Godot viewport images to /tmp.

class PreviewInput extends PlayerCommandSource:
	var held: bool = false
	var aim: Vector2 = Vector2.RIGHT
	func sample(_position: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.aim = aim
		command.attack_held = held
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var player: Player = scene.get_node("Player")
	var source := PreviewInput.new()
	player.add_child(source)
	player.command_source = source
	root.add_child(scene)
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
	var camera: CameraFollow = scene.get_node("Camera3D")
	var cycle: EnvironmentCycle = scene.get_node("World/EnvironmentCycle")
	cycle.set_process(false)
	var poses: Array[Vector3] = [Vector3(-7, 0, -1), Vector3(10, 0, 4), Vector3(30, 1, 18)]
	var names: Array[String] = ["grove", "river", "night"]
	for index in poses.size():
		source.aim = Vector2.DOWN if index == 0 else Vector2.RIGHT
		player.position = poses[index]
		player.velocity = Vector3.ZERO
		cycle.phase = 0.45 if index < 2 else 0.94
		cycle._process(0.0)
		camera.global_position = player.global_position + camera.offset
		for frame in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("/tmp/tofufu-" + names[index] + ".png")
		assert(error == OK)
	player.position = Vector3(18.9, 0, 3)
	player.velocity = Vector3.ZERO
	cycle.phase = 0.4
	cycle._process(0.0)
	camera.global_position = player.global_position + camera.offset
	source.held = true
	for tick in 60:
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-charge.png")
	source.held = false
	for tick in 15:
		await physics_frame
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-strike.png")
	print("Rendered QA screenshots: /tmp/tofufu-{grove,river,night,charge,strike}.png")
	scene.queue_free()
	await process_frame
	quit()
