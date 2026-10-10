extends SceneTree
## Render free-flight controls, a ridden macaw and the bird parked after landing.

class FlightInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 3: await physics_frame
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.weather.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.progression.progress.award_experience(CharacterProgress.threshold(8, true))
	var station := game.parrot_travel.perches.stations[0].global_position
	game.player.relocate(station + Vector3(0, 0.1, 3))
	game.player.set_physics_process(false)
	game.camera.position = station + Vector3(5, 4.5, 8)
	game.camera.look_at(station + Vector3.UP)
	await capture("jungle")
	var input := FlightInput.new()
	game.player.add_child(input)
	game.player.command_source = input
	game.parrot_travel.start(game.player)
	game.player.set_physics_process(true)
	input.move = Vector2.UP
	for tick in 70: await physics_frame
	input.move = Vector2.ZERO
	for tick in 25: await physics_frame
	game.camera.position = game.player.position + Vector3(5, 4.5, 8)
	game.camera.look_at(game.player.position)
	await capture("riding")
	root.size = Vector2i(960, 540)
	await capture("controls-small")
	root.size = Vector2i(1280, 720)
	game.parrot_travel.request_land(game.player)
	for tick in 150: await physics_frame
	game.player.set_physics_process(false)
	game.camera.position = game.player.position + Vector3(5, 4.5, 8)
	game.camera.look_at(game.player.position + Vector3.UP)
	await capture("parked")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-parrot-" + label + ".png")
