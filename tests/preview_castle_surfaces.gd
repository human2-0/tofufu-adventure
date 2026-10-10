extends SceneTree
## Actual game rendering of textured facade, all cutaway decks and royal courtyard.

var game: AdventureGame
var castle: LavaCastle

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 1000)
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 4: await physics_frame
	castle = game.world.volcanic.castle
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.castle_adventure.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.hud.visible = false
	game.chat.view.visible = false
	game.weather_view.visible = false
	game.cycle.world_environment.environment.fog_density = 0.00025
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.far = 1000
	game.player.global_position = castle.to_global(Vector3(0, 0, 65))
	_camera(Vector3(-74, 65, 102), Vector3(0, 13, 0), 100)
	await capture("facade")
	_camera(Vector3(43, 18, 51), Vector3(22, 14, 27), 28)
	await capture("masonry")
	for deck in 3:
		game.player.global_position = castle.to_global(Vector3(0, deck * 8.0 + 0.1, 20))
		_camera(Vector3(37, deck * 8.0 + 47, 48), Vector3(0, deck * 8.0, 0), 70)
		await capture("deck-" + str(deck + 1))
	game.player.global_position = castle.to_global(Vector3(0, 24.1, -12))
	_camera(Vector3(32, 52, 47), Vector3(0, 24, 0), 66)
	await capture("plaza")
	_camera(Vector3(-8, 32, 5), Vector3(0, 27, 21), 17)
	await capture("throne")
	game.player.global_position = castle.to_global(Vector3(0, 4, -53))
	_camera(Vector3(29, 28, -72), Vector3(4, 8, -37), 43)
	await capture("stairs")
	game.player.global_position = castle.to_global(Vector3(0, 0.1, 24))
	game.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	game.camera.reset_follow()
	await capture("gameplay")
	game.queue_free()
	for frame in 4: await process_frame
	quit()

func _camera(at: Vector3, target: Vector3, width: float) -> void:
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.size = width
	game.camera.position = castle.to_global(at)
	game.camera.look_at(castle.to_global(target))

func capture(label: String) -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-castle-surfaces-" + label + ".png")
