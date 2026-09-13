extends SceneTree
## Rendered guard, impact, dropped item and fist-slot QA using real commands.
class PreviewInput extends PlayerCommandSource:
	var command := PlayerCommand.new()
	func sample(_at: Vector3) -> PlayerCommand:
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
	scene.hud.toggle_help()
	scene.cycle.set_process(false)
	scene.cycle.phase = 0.4
	scene.cycle._process(0.0)
	scene.camera.offset *= 0.55
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
	var mob := TrainingMob.new()
	mob.position = Vector3(0, 0, 1.3)
	scene.add_child(mob)
	mob.set_physics_process(false)
	scene.combat.targets.append(mob.target)
	source.command.guard_held = true
	for index in 40:
		await physics_frame
	await _capture("guard")
	scene.encounters._hurt_player(12.0, mob.global_position)
	for index in 4:
		await process_frame
	await _capture("block")
	for index in 55:
		await physics_frame
	source.command.guard_held = false
	source.command.drop_pressed = true
	await physics_frame
	await process_frame
	source.command.drop_pressed = false
	await _capture("drop")
	source.command.punch_held = true
	for index in 4:
		await process_frame
	await _capture("punch")
	scene.queue_free()
	await process_frame
	quit()

func _capture(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-" + title + ".png")
