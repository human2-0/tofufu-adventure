extends SceneTree
## Real match settings remain local and live; culling preserves collision and recovery.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if value: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	GamePreferences.install_translations(self)
	var room := BattleRoom.new()
	room.options = [1, 1]
	root.add_child(room)
	room.practice()
	var game := BattleRoyaleGame.new()
	game.room = room
	game.preferences.path = "user://battle-graphics-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	var settings := game.settings
	var sprite := game.bodies[1].visuals
	check(sprite.visibility_range_end == BattleVisibility.COMBATANT_RANGE, "combatants have the same safe viewing range at every quality")
	var before := game.match_state.time
	game.hud.graphics_requested.emit()
	check(settings.panel.visible and game.hud.exit_panel.visible, "match menu opens local graphics with controls blocked")
	game._physics_process(1.0 / 60)
	check(game.match_state.time > before and not paused and not game.local_input.enabled, "settings do not pause match or leave movement enabled")
	var scenery := settings.scenery
	check(scenery.geometry.size() > 100, "all authored scenery receives native distance culling")
	var ground := game.world.get_node("RollingGround") as MeshInstance3D
	check(ground.get_child_count() > 0, "ground retains its physical collision")
	var ray := PhysicsRayQueryParameters3D.create(Vector3(-25, 30, -25), Vector3(-25, -10, -25), 1)
	var hit_before := game.world.get_world_3d().direct_space_state.intersect_ray(ray)
	settings.panel.performance_requested.emit()
	check(game.preferences.render_scale == 0.65 and game.preferences.frame_limit == 60 and not game.preferences.adaptive_resolution, "performance preset applies lower GPU pixel cost immediately")
	check(game.preferences.graphics.scenery_distance == 160 and not game.preferences.graphics.shadows, "preset reduces distant rendering and disables dynamic shadows")
	var fog: Environment = game.world.get_node("EnvironmentCycle").world_environment.environment
	check(fog.fog_mode == Environment.FOG_MODE_DEPTH and fog.fog_depth_end == 144, "distance haze conceals the short scenery cutoff")
	game.world.get_node("EnvironmentCycle")._process(0)
	scenery._process(0)
	check(fog.fog_density == 1, "day/night updates cannot expose culled scenery through weak depth fog")
	var hit_after := game.world.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit_before.is_empty() and hit_before == hit_after, "rendering changes preserve exact physical cover and terrain")
	for index in scenery.geometry.size():
		if scenery._ranges[index] > 0:
			check(scenery.geometry[index].visibility_range_end <= scenery._ranges[index], "authored grass/detail culling never becomes farther")
		else:
			check(scenery.geometry[index].visibility_range_end >= 160, "close combat cover stays inside minimum scenery range")
	var saved := GamePreferences.new()
	saved.path = game.preferences.path
	saved.load_preferences()
	check(saved.render_scale == 0.65 and saved.graphics.scenery_distance == 160 and not saved.graphics.shadows, "graphics choices persist independently of match state")
	settings.panel.scenery_requested.emit(0, true)
	check(fog.fog_mode == Environment.FOG_MODE_EXPONENTIAL, "full scenery restores the authored atmosphere")
	check(sprite.visibility_range_end == BattleVisibility.COMBATANT_RANGE, "full scenery does not grant farther enemy visibility")
	for index in scenery.geometry.size():
		check(scenery.geometry[index].visibility_range_end == scenery._ranges[index], "full map restores each authored culling range")
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.content_scale_size = dimensions
			root.size = dimensions
			settings.open()
			for frame in 5: await process_frame
			check(settings.panel.frame.get_global_rect().position.x >= 0 and settings.panel.frame.get_global_rect().end.x <= dimensions.x, "graphics panel stays within width")
			check(settings.panel.frame.size.y > dimensions.y * 0.6, "first open provides space for actual rendering controls")
			check(settings.panel.frame.get_global_rect().position.y >= 0 and settings.panel.frame.get_global_rect().end.y <= dimensions.y, "graphics scrolls inside the screen height")
			check(settings.panel.close_button.get_global_rect().position.y >= 0 and settings.panel.close_button.get_global_rect().end.y <= dimensions.y, "settings back action stays visible: %s %s frame=%s root=%s" % [locale, dimensions, settings.panel.frame.get_global_rect(), settings.panel._root.size])
	settings.panel.closed.emit()
	check(not settings.panel.visible and game.hud.exit_panel.visible, "back returns to the match menu")
	settings.open()
	room.migration.paused.emit()
	check(not settings.panel.visible, "recovery closes local settings")
	DirAccess.remove_absolute(saved.path)
	game.queue_free()
	room.queue_free()
	await process_frame
	print("Battle graphics: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
