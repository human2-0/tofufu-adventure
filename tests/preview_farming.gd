extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.position = game.world.ground_point(-5.3, 7.6, 0.1)
	game.camera.position = game.player.position + game.camera.offset
	game.cycle.phase = 0.4
	game.cycle.set_process(false)
	game.cycle._process(0)
	for i in 30: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/soybean-garden.png")
	game.farming.interact(game.farming.plots[3])
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/soybean-harvest.png")
	quit()
