extends SceneTree
## Real match gunfire on the minimap and expanded map, desktop/compact and EN/PL.
const OUTPUT := ".codex/visualizations/2026/10/21/battle-radar"
var output: String

func _initialize() -> void:
	_run.call_deferred()

func _shot(title: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(title + ".png"))

func _run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	GamePreferences.install_translations(self)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var room := BattleRoom.new()
	room.options = [3, 1, 1]
	root.add_child(room)
	room.practice()
	var game := BattleRoyaleGame.new()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	var center := game.world.ground_point(-22, -22, 0.1)
	var offsets: Array[Vector3] = [Vector3.ZERO, Vector3(-35, 0, -35), Vector3(75, 0, 10), Vector3(0, 0, 85)]
	for slot in offsets.size():
		game.bodies[slot].position = center + offsets[slot]
		var row: Array = game.match_state.rows[slot]
		for axis in 3: row[axis] = game.bodies[slot].position[axis]
	game.camera.reset_follow()
	game.presentation.gunfire.reset()
	for slot in [1, 2, 3]:
		var gun := game.combat.fighters[slot].combat.gun
		gun.step(true, false, Vector2.DOWN, game.bodies[slot].position + Vector3(0, 1, 20), 1.0 / 60)
	game.presentation.update(0)
	assert(game.hud.radar.gunfire.size() == 2, "only two enemy shot origins appear")
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			game._update_hud()
			for expanded in [false, true]:
				game.hud.radar.expanded = expanded
				game.hud._responsive()
				await _shot("%s-%s-%s" % [dimensions.x, locale, "map" if expanded else "mini"])
	game.presentation.gunfire.update(2.01)
	assert(game.hud.radar.gunfire.is_empty(), "markers disappear without another shot")
	await _shot("expired")
	game.queue_free()
	room.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("Battle radar native preview: PASS")
	quit()
