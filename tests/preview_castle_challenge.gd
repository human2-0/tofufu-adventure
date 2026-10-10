extends SceneTree
## Actual shoulder/FPP cameras, acknowledged glyphs, hinged treasure and fast-fire VFX.

var game: AdventureGame
var flow: CastleAdventure
var output: String = "/tmp/tofufu-castle-challenge-"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	for tick in 4: await physics_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.weather.set_physics_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.43
	game.cycle._process(0)
	game.chat.view.visible = false
	game.weather_view.visible = false
	game.cycle.world_environment.environment.fog_density = 0.00025
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	flow = game.castle_adventure
	flow.set_physics_process(false)
	flow.encounter.authority(false)
	game.world_items.set_physics_process(false)
	game.world_items.set_process(false)
	game.player.command_source.enabled = true
	for deck in 3:
		var hub := flow.castle.floors[deck].trial.controls[0].global_position + Vector3(1.7, 0, 1.7)
		game.player.relocate(hub + Vector3(0, 0.05, 0.7))
		var looking := PlayerCommand.new()
		looking.aim = Vector2.UP
		looking.face_aim = true
		game.player.visuals.present(looking, Vector3.ZERO, true, false, 0.016)
		game.world_items.focused_kind = "castle"
		game.world_items.focused_plot = deck * 4
		flow.notice_time = 0
		game.shooting_view.cycle_mode()
		game.camera.yaw = 0
		game.camera.pitch = -0.2
		game.camera.reset_follow()
		game.camera._sample_collision()
		game.camera._follow_shoulder(1)
		await capture("shoulder-" + str(deck))
		game.shooting_view.cycle_mode()
		game.camera.pitch = -0.35
		game.camera.reset_follow()
		await capture("fpp-" + str(deck))
		if deck == 1:
			flow.state.operate(6)
			flow.state.operate(4)
			flow.present_state()
			flow.castle.floors[deck].trial.feedback.step(1)
			flow.notice_time = 0
			await capture("memory-lit")
			flow.state.operate(5)
			flow.present_state()
			flow.castle.floors[deck].trial.set_process(false)
			await capture("memory-wrong")
		game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	for side in 3:
		var station := flow.castle.floors[1].trial.controls[2 if side == 0 else (0 if side == 1 else 1)]
		var offset: Vector3 = [Vector3.FORWARD * 1.5, Vector3.RIGHT * 1.5, Vector3.LEFT * 1.5][side]
		game.player.relocate(station.global_position + offset + Vector3.UP * 0.05)
		game.world_items.focused_plot = 6 if side == 0 else (4 if side == 1 else 5)
		game.camera.yaw = [PI, PI * 0.5, -PI * 0.5][side]
		game.camera.pitch = -0.28
		game.camera.reset_follow()
		await capture("fpp-side-" + str(side))
	game.shooting_view.cycle_mode()
	game.hud.visible = false
	game.world_items.focused_kind = ""
	var chest := flow.treasure.chest(0)
	game.player.relocate(chest.global_position + chest.global_basis.z * 2)
	game.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	game.camera.position = chest.to_global(Vector3(2.4, 2.0, 3.0))
	game.camera.look_at(chest.global_position + Vector3.UP * 0.7)
	await capture("chest-closed")
	chest.present(true, false, true)
	await capture("chest-opening", 3)
	for frame in 40: await process_frame
	await capture("chest-open")
	game.player.relocate(flow.castle.to_global(Vector3(0, 24.1, -10)))
	var king := flow.encounter.king
	king.global_position = flow.castle.to_global(Vector3(0, 24, 4))
	king.facing = Vector2.UP
	king.pose = "release"
	king.skill = 4
	king.phase = 2
	king.active = true
	king.cast = 0.36
	king.spells.authoritative = true
	king.spells.set_physics_process(false)
	for i in 4:
		king.spells.bolt(flow.castle.to_global(Vector3(-0.7 + i * 0.35, 25.3, -1.5 - i * 1.5)), Vector3.FORWARD, 34, true)
	game.camera.position = flow.castle.to_global(Vector3(13, 31, -17))
	game.camera.look_at(king.global_position + Vector3.UP)
	game.hud.visible = true
	await capture("king-chunks")
	game.queue_free()
	for frame in 4: await process_frame
	quit()

func capture(label: String, frames: int = 10) -> void:
	for frame in frames: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + label + ".png")
