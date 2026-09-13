extends SceneTree
## Real Godot render of early, intermediate and capped progression HUD states.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	(scene.player.command_source as LocalPlayerInput).enabled = false
	scene.hud.toggle_help()
	scene.player.position = scene.world.ground_point(19.3, 13.4, 0.1)
	scene.camera.position = scene.player.position + scene.camera.offset
	for mob: TrainingMob in scene.encounters.mob_nodes: mob.set_physics_process(false)
	for rank in [1, 25, 99]:
		var data: Dictionary = scene.progression.progress.capture()
		data.experience = CharacterProgress.threshold(rank, true)
		for skill: String in ["sword", "fist", "defence"]:
			data.practice[skill] = CharacterProgress.threshold(rank) + (5 if rank < 99 else 0)
		scene.progression.progress.restore(data)
		scene.hud.announce("")
		await capture("rank-%d" % rank)
	root.size = Vector2i(960, 540)
	await capture("compact")
	scene.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 20: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/tofufu-progression-" + label + ".png") == OK)
