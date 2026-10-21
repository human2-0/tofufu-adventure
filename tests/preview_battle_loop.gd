extends SceneTree
## Native staged match values, real chest transactions, recap and a real offline replay.
const OUTPUT := ".codex/visualizations/2026/10/21/battle-loop"
var output: String
var app: Node
var flow: BattleRoyaleFlow

func _initialize() -> void:
	_run.call_deferred()

func _shot(name: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func _sizes(kind: String, refresh: Callable) -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			refresh.call()
			if flow.game != null and flow.game.composed: flow.game.presentation.update(0)
			await _shot("%s-%d-%s" % [kind, dimensions.x, locale])

func _run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	app = load("res://game/app/bootstrap/launch.tscn").instantiate()
	load("res://tests/lobby_test_transport.gd").inject(app)
	app.get_node("BattleTransport").free()
	var fake: SessionTransport = load("res://tests/lobby_test_transport.gd").new()
	app.add_child(fake)
	app.battle_transport = fake
	var token := str(Time.get_ticks_usec())
	app.preferences.path = "user://battle-loop-preview-%s.cfg" % token
	app.updates.path = "user://battle-loop-preview-updates-%s.cfg" % token
	app.battle.rounds.career.path = "user://battle-loop-preview-career-%s.json" % token
	root.add_child(app)
	await process_frame
	if is_instance_valid(app.updates.panel): app.updates.panel.hide()
	flow = app.battle
	flow.rounds.career.xp = 640
	flow._options = [3, 1, 1]
	flow.show_lobby()
	await _sizes("lobby", flow._refresh)
	flow._practice()
	await _loaded()
	var game := flow.game
	BattleTestDeployment.finish(game)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	# Preview driver stages a later snapshot; gameplay tests verify the real clocks.
	game.match_state.time = 110
	game.match_state.stats[0][4] = 95.0
	var opened := 0
	for chest: Array in game.match_state.chests:
		game.bodies[0].position = Vector3(chest[1], chest[2], chest[3]) + Vector3(0, 0.05, 2)
		if BattleChestLoot.open(game.pack, 0, int(chest[0])): opened += 1
		if opened == 3: break
	assert(opened == 3)
	var at := game.world.ground_point(-22, -22, 0.08)
	for site: Array in game.match_state.deployment.sites:
		var point := Vector3(site[0], site[1], site[2])
		if not BattleRing.outside(point, 110, game.match_state.circle) and BattleRing.outside(point, 132, game.match_state.circle):
			at = game.world.ground_point(point.x, point.z + 1.6, 0.08)
			break
	for slot in game.bodies.size():
		game.bodies[slot].position = at + Vector3(slot * 4, 0, 0)
		for axis in 3: game.match_state.rows[slot][axis] = game.bodies[slot].position[axis]
	game.camera.reset_follow()
	game.squad.request(at + Vector3(12, 0, 6))
	game.match_state.hit(2, 80, 0)
	game._update_hud()
	await _sizes("goals", game._update_hud)
	game.hud.radar.expanded = true
	game.hud._responsive()
	await _sizes("forecast", game._update_hud)
	game.hud.radar.expanded = false
	game.hud._responsive()
	for slot in [2, 3]: game.match_state.hit(slot, 200, 0)
	game.match_state.step(0.01)
	game.local_input.enabled = false
	game._update_hud()
	await _sizes("results", game._update_hud)
	var old_epoch := flow.room.epoch
	game.replay_requested.emit()
	await _loaded()
	assert(flow.room.epoch != old_epoch and flow.game.match_state.deployment.stage == 0)
	assert(flow.rounds.career.totals.practice[0] == 1)
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		flow.game.local_input.enabled = false
		flow.game.deployment.update()
		flow.game._update_hud()
		flow.game.presentation.update(0)
		await _shot("replayed-plants-640-%s" % locale)
	var cleanup: Array[String] = [app.preferences.path, app.updates.path, flow.rounds.career.path]
	flow.leave()
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	for path in cleanup:
		for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("Battle loop native preview and replay: PASS")
	quit()

func _loaded() -> void:
	while flow.game == null or not flow.game.composed:
		if flow.game != null and not flow.game.prepared.is_connected(flow.game.set_physics_process.bind(false)):
			flow.game.prepared.connect(flow.game.set_physics_process.bind(false))
		await physics_frame
