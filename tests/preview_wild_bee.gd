extends SceneTree
## Render authored southern bee locations, attack warning and a sting in flight.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.hud.hide()
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.weather.set_physics_process(false)
	game.cycle.phase = 0.18
	game.cycle.set_process(false)
	game.cycle._process(0.0)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	var bee := game.encounters.mob_nodes[39] as WildBee
	game.player.position = game.world.ground_point(-5, 76, 0.1)
	game.loadout.select(2)
	var center := game.world.ground_point(-2, 73, 0.8)
	game.camera.position = center + Vector3(0, 8, 15)
	game.camera.look_at(center)
	bee.quarry = game.player
	bee._choose_direction(0.01)
	bee.facing = Vector3(bee._sting_aim.x, 0, bee._sting_aim.z).normalized()
	await capture("warning")
	bee._choose_direction(0.71)
	bee.sting.step(0.2, bee.protected_area, bee.get_rid())
	await capture("sting")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-bee-" + label + ".png")
