extends SceneTree
## Actual game rendering of aimed first-shot accuracy, spraying and recovery.
var game: Node3D
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.player.position = game.world.ground_point(23, 18) + Vector3.UP * 0.05
	game.shooting_view.shoulder = true
	game.camera.set_shoulder(true)
	game.combat.equipment.knife_selected = false
	game.combat.sword.visible = false
	game.combat.gun.selected = true
	await _ticks(20, false)
	await _capture("cold")
	await _ticks(95, true)
	assert(game.combat.gun.recoil.heat == 1.0)
	await _capture("spray")
	await _ticks(100, false)
	assert(game.combat.gun.recoil.heat == 0.0)
	await _capture("recovered")
	game.queue_free()
	await process_frame
	quit()

func _ticks(count: int, trigger: bool) -> void:
	var command := PlayerCommand.new()
	command.aim = Vector2.UP
	for index in count:
		game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60.0)
		game.combat.gun.step(trigger, true, Vector2.UP, game.player.position + Vector3(0,1,-50), 1.0 / 60.0)
		await physics_frame
		await process_frame

func _capture(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-recoil-%s.png" % title)
