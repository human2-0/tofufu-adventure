extends SceneTree
## Native snapshots of the actual Royale world, HUD and textured circle boundary.
const OUTPUT := "res://.codex/visualizations/2026/10/22/battle-hud/"
var game: BattleRoyaleGame
var room: BattleRoom
var view: BattleAimView

func _initialize() -> void: _run.call_deferred()

func _shot(name: String) -> void:
	game.deployment.update()
	game._update_hud()
	game.presentation.update(0.3)
	for frame in 12:
		for body in game.bodies:
			var command := PlayerCommand.new()
			command.aim = Vector2.UP
			body.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name + ".png")

func _sizes(name: String) -> void:
	if OS.get_cmdline_user_args().has("help-only") and name != "help": return
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			await _shot("%s-%d-%s" % [name, dimensions.x, locale])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	GamePreferences.install_translations(self)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	room = BattleRoom.new()
	room.options = [3, 1, 1]
	root.add_child(room)
	room.practice()
	game = BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	room.set_process(false)
	game.set_physics_process(false)
	BattleTestDeployment.finish(game)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	for child in game.get_children():
		if child is BattleAimView: view = child
	game.hud.radar.terrain_map.get_image().save_png(OUTPUT + "terrain-source.png")
	game.match_state.circle = BattleRing.CENTER
	game.match_state.time = BattleRing.start_of(5) + BattleRing.HOLD + 1
	var at := game.world.ground_point(-22, -14, 0.08)
	for slot in game.bodies.size():
		game.bodies[slot].position = at + Vector3(slot * 3, 0, -slot * 3)
		game.match_state.rows[slot][0] = game.bodies[slot].position.x
		game.match_state.rows[slot][1] = game.bodies[slot].position.y
		game.match_state.rows[slot][2] = game.bodies[slot].position.z
		var command := PlayerCommand.new()
		command.aim = Vector2.UP
		game.bodies[slot].visuals.present(command, Vector3.ZERO, true, false, 1)
	var fighter := game.combat.fighters[0]
	for i in 4:
		fighter.loadout.equipment.set_slot("support_%d" % (i + 1), ItemStack.new(BattleItems.make(27 + i), 3))
	fighter.loadout.equipment.set_slot("combat_1", ItemStack.new(BattleItems.make(8), 1))
	fighter.loadout.equipment.set_slot("combat_2", ItemStack.new(BattleItems.make(11), 1))
	fighter.loadout.select(2)
	game.pack.refresh(0)
	game.combat.capture()
	game.match_state.rows[0][8] = 76
	game.match_state.rows[0][9] = 32
	game.match_state.rows[0][12] = 2
	game.match_state.stats[0][0] = 68
	game.match_state.stats[0][2] = 2
	game.match_state.stats[0][4] = 90
	game.local_input.enabled = true
	game.camera.yaw = 0
	game.camera.pitch = 0.14
	game.camera.reset_follow()
	game.match_state.time = BattleRing.start_of(5)
	await _sizes("safe-hold")
	game.match_state.time = BattleRing.start_of(5) + BattleRing.HOLD + 1
	await _sizes("behind-closing")
	view._set_behind(false)
	game.camera.reset_follow()
	await _sizes("overhead-closing")
	game.hud.toggle_map()
	await _sizes("expanded-map")
	game.hud.toggle_map()
	view._set_behind(true)
	game.camera.yaw = 0
	game.bodies[0].position = game.world.ground_point(-22, 2, 0.08)
	game.camera.reset_follow()
	await _sizes("outside-storm")
	game.hud.exit_panel.show()
	await _sizes("help")
	game.hud.exit_panel.hide()
	game.room.status = "Match paused · Finding a new host"
	game.room.phase = "recovering"
	game.playing = false
	await _sizes("recovery")
	game.queue_free()
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("Native Royale HUD/storm preview: PASS")
	quit()
