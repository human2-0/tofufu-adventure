extends SceneTree
## Native actual-game views; staged encounters use the existing adventure art.
const OUTPUT := ".codex/visualizations/2026/10/21/battle-balance/hunts"
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
			if flow.game != null: flow.game.presentation.update(0)
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
	app.preferences.path = "user://hunt-preview-%s.cfg" % token
	app.updates.path = "user://hunt-preview-updates-%s.cfg" % token
	app.battle.rounds.career.path = "user://hunt-preview-career-%s.json" % token
	root.add_child(app)
	await process_frame
	if is_instance_valid(app.updates.panel): app.updates.panel.hide()
	flow = app.battle
	flow._options = [3, 1]
	flow.show_lobby()
	await _sizes("lobby", flow._refresh)
	flow._practice()
	while flow.game == null or not flow.game.composed:
		if flow.game != null and not flow.game.prepared.is_connected(flow.game.set_physics_process.bind(false)):
			flow.game.prepared.connect(flow.game.set_physics_process.bind(false))
		await physics_frame
	var game := flow.game
	BattleTestDeployment.finish(game)
	game.match_state.time = 13
	game.local_input.enabled = false
	var at := game.world.ground_point(-22, -22, 0.08)
	for slot in game.bodies.size():
		game.bodies[slot].position = at + Vector3(slot * 4, 0, 0)
		if slot > 0: game.bodies[slot].hide()
	for id in 3:
		var mob := game.mobs.actors[id]
		mob.position = game.world.ground_point(at.x + (id - 1) * 3, at.z + 5, 0.08)
		if mob is ArmoredSnail: mob.facing = Vector3.FORWARD
		if mob is WildBee: mob.facing = Vector3.FORWARD
	for id in 3:
		game.mobs.actors[id].quarry = game.bodies[0]
		game.mobs.ranged[id].rest = 0
		game.mobs.ranged[id].step(0, true)
	game.camera.reset_follow()
	game.deployment.update()
	game._update_hud()
	await _sizes("hunts", game._update_hud)
	for id in 3:
		var shot := game.mobs.ranged[id]
		shot.step(shot.profile.windup + 0.01, true)
	for frame in 4:
		for id in 3: game.mobs.ranged[id].step(1.0 / 60, false)
		await physics_frame
	for id in 3:
		var shot := game.mobs.ranged[id]
		if shot._flying(): shot.projectile.place_visual(shot.projectile.global_position)
	await _sizes("ranged-flight", game._update_hud)
	for id in 3: game.mobs.ranged[id].restore(game.mobs.ranged[id].capture())
	for id in 3:
		var mob := game.mobs.actors[id]
		mob.target.receive_attack(1000, Vector3.ZERO, Damageable.HitKind.SOY, mob.position + Vector3.UP * 0.2, game.combat.fighters[0].health)
	game.pack.field.update(false)
	await _sizes("hunt-loot", game._update_hud)
	game.match_state.rows[0][13] = 2
	game.match_state.rows[0][8] = 0
	game.match_state.stats[0][4] = 93
	game._update_hud()
	await _sizes("recap", game._update_hud)
	var cleanup: Array[String] = [app.preferences.path, app.updates.path, flow.rounds.career.path]
	flow.leave()
	app.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	for path in cleanup:
		for suffix in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	print("Native Royale hunts preview: PASS")
	quit()
