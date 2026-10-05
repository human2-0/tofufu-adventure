extends SceneTree
## Render the connected islands, tofu-block resident and landing perch in Godot.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 4: await physics_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.camera.set_physics_process(false)
	game.player.relocate(CloudTerrain.point(-8, 247, 0.1))
	game.player.set_physics_process(false)
	game.camera.position = Vector3(58, 110, 330)
	game.camera.look_at(Vector3(-8, 57, 270))
	await capture("overview")
	var npc := game.world.cloud_realm.godfufu
	game.player.relocate(npc.global_position + Vector3(2, 0.1, 3))
	game.camera.position = npc.global_position + Vector3(7, 5.5, 12)
	game.camera.look_at(npc.global_position + Vector3.UP * 2.3)
	await capture("godfufu")
	game.player.relocate(CloudTerrain.point(-8, 247, 0.1))
	game.camera.position = game.player.position + Vector3(9, 7, 13)
	game.camera.look_at(game.player.position + Vector3(0, 1, 0))
	await capture("landing")
	game.queue_free()
	for frame in 5: await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-cloud-" + label + ".png")
