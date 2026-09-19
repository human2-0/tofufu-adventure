extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var game := load("res://game/app/main.tscn").instantiate() as Node3D
	game.play_opening = false
	root.add_child(game)
	await process_frame
	game.player.position = game.world.ground_point(19.3, 14.3)
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	game.shooting_view.set_process_unhandled_input(false)
	game.camera.yaw = 0.0
	game.camera.pitch = 0.0
	for slot in [1, 2, 3, 4]:
		game.combat.equipment.step(Vector2.UP, false, false, false, false, slot, 0.016)
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-fpp-%d.png" % slot)
	game.player.set_physics_process(false)
	game.combat.equipment.step(Vector2.UP, true, false, false, false, 1, 0.016)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-fpp-guard.png")
	game.combat.equipment.step(Vector2.UP, false, false, false, false, 4, 0.016)
	game.combat.sotjet.aiming = true
	game.player.set_physics_process(false)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-fpp-ads.png")
	game.queue_free()
	await process_frame
	quit()
