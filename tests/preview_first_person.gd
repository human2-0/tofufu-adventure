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
	for slot in [1, 2, 3, 4, 5]:
		var id: String = ["knife", "", "soy_gun", "sotjet", "sproutwood_staff"][slot - 1]
		game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon(id), 1) if not id.is_empty() else null)
		game.loadout.select(1)
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-fpp-%d.png" % slot)
	game.player.set_physics_process(false)
	game.combat.equipment.step(Vector2.UP, true, false, false, false, 1, 0.016)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-fpp-guard.png")
	game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	for ads in [false, true]:
		game.combat.sotjet.aiming = ads
		await create_timer(0.4).timeout
		for frame in 12:
			game.combat.sotjet.step(true, ads, Vector2.UP, game.camera.global_position - game.camera.global_basis.z * 30.0, 1.0 / 60.0)
			await physics_frame
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-fpp-stream-%s.png" % ads)
	game.queue_free()
	await process_frame
	quit()
