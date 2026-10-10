extends SceneTree
## Rendered stair joints, trial controls, combat art, spell warnings and defeated king.

var game: AdventureGame
var flow: CastleAdventure

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
	flow.encounter.king.spells.authoritative = true
	flow.encounter.king.spells.set_physics_process(false)
	game.hud.visible = false
	game.player.global_position = flow.castle.to_global(Vector3(0, 4, -53))
	game.camera.position = flow.castle.to_global(Vector3(29, 28, -72))
	game.camera.look_at(flow.castle.to_global(Vector3(4, 8, -37)))
	await capture("stairs")
	var hub := flow.castle.floors[0].trial.controls[0].global_position
	game.player.global_position = hub + Vector3(1.5, 0, 2)
	game.camera.position = hub + Vector3(7, 12, 15)
	game.camera.look_at(hub + Vector3(1.5, 1, 0))
	await capture("trial")
	game.player.global_position = flow.castle.to_global(Vector3(0, 24, 18))
	var king := flow.encounter.king
	king.global_position = flow.castle.to_global(Vector3(0, 24, 5))
	king.facing = Vector2.DOWN
	king.pose = "channel"
	game.camera.position = king.global_position + Vector3(9, 9, 15)
	game.camera.look_at(king.global_position + Vector3.UP * 2)
	await capture("casting")
	for i in 5:
		king.spells.mark(flow.castle.to_global(Vector3(-7 + i * 3.5, 24, -3)), 1.3)
	game.player.global_position = flow.castle.to_global(Vector3(3, 24, -10))
	game.camera.position = flow.castle.to_global(Vector3(32, 45, 43))
	game.camera.look_at(flow.castle.to_global(Vector3(0, 24, 0)))
	game.hud.visible = true
	king.active = true
	king.phase = 2
	king.target.current = king.target.maximum * 0.5
	king.cast = 1.0
	king.skill = 1
	flow.party.burns["solo"] = [4.8, 0.8]
	await capture("arena")
	for field in king.spells.fields: field[4] = 0.2
	king.pose = "release"
	await capture("eruption")
	game.player.global_position = flow.castle.to_global(Vector3(0, 24, 8))
	game.camera.reset_follow()
	await capture("gameplay")
	king.active = false
	king.pose = "defeat"
	king.spells.clear()
	flow.party.burns.clear()
	game.hud.visible = false
	game.camera.position = king.global_position + Vector3(7, 6, 13)
	game.camera.look_at(king.global_position + Vector3.UP * 2)
	await capture("defeat")
	game.queue_free()
	for frame in 4: await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-castle-" + label + ".png")
