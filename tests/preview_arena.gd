extends SceneTree
## Native arena HUD preview over the real battlefield at desktop/compact sizes.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.relocate(game.world.duel_arena.spawn_positions()[0] + Vector3.UP * 0.12)
	for mob: TrainingMob in game.encounters.mob_nodes: mob.set_physics_process(false)
	var display := {"phase": "loadout", "match": 1, "participant": true, "names": ["YOU · Mochi", "Soybean"], "scores": [0, 0],
		"status": "AGREE ON YOUR LOADOUT · 56s", "choice": {"ranged": "soy_gun", "melee": "knife", "ready": false},
		"readiness": "Mochi: CHOOSING · Soygun\nSoybean: READY · Soyjet"}
	game.hud.arena.present(display)
	game.hud._notice.hide()
	await _capture("loadout")
	display.phase = "fight"
	display.scores = [6, 4]
	display.status = "ROUND 11 · FIRST TO 10 · 2× PROJECTILE SPEED"
	game.hud.arena.present(display)
	await _capture("fight")
	root.size = Vector2i(960, 720)
	await _capture("compact")
	display.phase = "complete"
	display.scores = [10, 4]
	display.status = "MOCHI WINS THE DUEL!"
	display.winner_index = 0
	game.hud.arena.present(display)
	await _capture("winner")
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	display.phase = "loadout"
	display.scores = [0, 0]
	display.status = "AGREE ON YOUR LOADOUT · 56s"
	display.winner_index = -1
	game.hud.arena.present(display)
	await _capture("first-person-setup")
	assert(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	display.phase = "fight"
	display.status = "ROUND 1 · FIRST TO 10 · 2× PROJECTILE SPEED"
	game.hud.arena.present(display)
	await _capture("first-person-fight")
	assert(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	game.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 24: await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/tofufu-arena-" + label + ".png") == OK)
