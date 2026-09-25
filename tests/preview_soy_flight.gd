extends SceneTree
## Render moving soybeans through overhead and first-person focused firing.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var game := load("res://game/app/main.tscn").instantiate() as Node3D
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.position = Vector3(0, 0.1, 3)
	game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))
	game.loadout.select(1)
	var gun: SoyGun = game.combat.gun
	gun.spread_multiplier = 0
	var command := PlayerCommand.new()
	command.aim = Vector2.UP
	game.player.visuals.attack_facing = Vector2.UP
	for first_person in [false, true]:
		if first_person:
			game.shooting_view.cycle_mode()
			game.shooting_view.cycle_mode()
		game.camera.yaw = 0
		game.camera.pitch = 0
		gun.aiming = true
		for frame in 30:
			game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)
			await physics_frame
			await process_frame
		for tick in 24:
			gun.step(true, true, Vector2.UP, Vector3(0, 0.95, -30), 1.0 / 60)
			game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)
			await physics_frame
			await process_frame
			if tick in [0, 2, 5, 12]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("/tmp/soy-flight-%s-%d.png" % ["fpp" if first_person else "top", tick])
	game.queue_free()
	await process_frame
	quit()
