extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func _run() -> void:
	var app := preload("res://game/app/launch.tscn").instantiate()
	app.store.directory = "user://test_map"
	app.preferences.path = "user://test_map.cfg"
	root.add_child(app)
	app._start(0, {"name": "Map test", "opening_complete": true})
	var game: Node3D = app.game
	await process_frame
	game.map._process(0)
	check(game.map.markers().size() == 1, "unvisited NPCs and factory are hidden")
	check(game.map.exploration.visited(Vector2.ZERO), "spawn area revealed")
	check(not game.map.exploration.visited(Vector2(25, -25)), "distant area remains hidden")
	for npc: Node3D in game.world.map_npcs.values():
		game.map.exploration.reveal(game.map._map_position(npc))
	check(game.map.markers().size() == 5, "visited NPCs and factory are mapped")
	check(game.map.markers().any(func(row: Dictionary) -> bool: return row.label == "Gigalopolis · Tofu Factory"), "factory appears east of meadow on the map")
	var kaji_label: Label3D = game.world.weapon_merchant.get_node("ResidentTitle")
	var mayor_label: Label3D = game.world.quest_npc.get_node("ResidentTitle")
	check(kaji_label.text == "Kaji · Gear", "Kaji's label shows the shop without a placeholder subtitle")
	check(mayor_label.text == "Mayor Mame", "Mayor Mame's label has no coming-soon subtitle")
	game.exploration.restore_places(["Fufufarm Village / Shops coming soon", "Mayor Mame / Quests coming soon"])
	check(game.exploration.found_places().has("Fufufarm Village / Kaji's gear shop"), "older village discovery name upgrades without rediscovery")
	check(game.exploration.found_places().has("Mayor Mame / Quests"), "older quest discovery name upgrades without rediscovery")
	var canvas: MapCanvas = game.map.view.full
	canvas.size = Vector2(800, 400)
	check(canvas.project_point(canvas.bounds.get_center()).is_equal_approx(Vector2(400, 200)), "center projection preserves aspect ratio")
	check(canvas.project_point(canvas.bounds.position).y < canvas.project_point(canvas.bounds.end).y, "negative Z is north")
	check(canvas.bounds.has_point(Vector2(40, 152)), "map includes the expanded desert crossing")
	check(canvas.bounds.has_point(Vector2(40, 320)), "map includes expanded southern jungle")
	check(canvas.bounds.has_point(Vector2(-40, -156)), "map includes expanded northern underwater world")
	check(canvas.bounds.has_point(Vector2(40, -320)), "map includes expanded northern frozen land")
	game.map.view.set_mini_zoom(1.0)
	var mini: MapCanvas = game.map.view.mini
	check(mini.visible_bounds().size == Vector2(44, 44), "minimap shows a local crop")
	game.map.view.zoom_in.pressed.emit()
	check(mini.visible_bounds().size.x < 44, "+ button narrows minimap")
	game.map.view.zoom_out.pressed.emit()
	check(is_equal_approx(mini.zoom, 1.0), "minus button widens minimap")
	game.map.view.set_mini_zoom(99)
	check(mini.zoom == 2.5 and game.map.view.zoom_in.disabled, "zoom-in limit")
	game.map.view.set_mini_zoom(0)
	check(mini.zoom == 0.5 and game.map.view.zoom_out.disabled, "zoom-out limit")
	game.map.view.set_mini_zoom(1.25)
	var stored := ConfigFile.new()
	stored.load(app.preferences.path)
	check(is_equal_approx(stored.get_value("map", "zoom", 0), 1.25), "custom zoom persists in preferences")
	game.map.view.set_mini_zoom(1.0)
	game.player.position = Vector3(20, 0, 4)
	game.map._process(0)
	check(mini.center == Vector2(20, 4), "minimap follows player")
	check(mini.project_point(mini.center).is_equal_approx(mini.size * 0.5), "player remains centered")
	game.shooting_view.shoulder = true
	game.camera.rotation = Vector3(-0.5, PI / 2, 0)
	game.map._process(0)
	check(mini.heading.is_equal_approx(Vector2.LEFT), "look arrow follows camera in shoulder view")
	game.shooting_view.shoulder = false
	game.map._process(0)
	check(mini.heading == game.shooting_view.local_input.focus_direction(), "overhead arrow follows pointer aim")
	var focus := canvas.project_point(Vector2(29, 20))
	canvas.zoom_at(focus, 4)
	check(canvas.zoom == 4 and canvas.unproject_point(focus).distance_to(Vector2(29, 20)) < 0.01, "zoom preserves point under cursor")
	canvas.zoom = 8
	canvas.center = Vector2.ZERO
	var before_drag := canvas.center
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	canvas._gui_input(press)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(30, 0)
	canvas._gui_input(motion)
	press.pressed = false
	canvas._gui_input(press)
	check(canvas.center.x < before_drag.x, "drag pans full map")
	canvas.reset_overview()
	var saved := AdventureSnapshot.capture(game, "Map save", 0)
	check(SaveStore.valid(saved), "save accepts bounded exploration mask")
	game.map.restore_exploration("")
	check(not game.map.exploration.visited(Vector2.ZERO), "reset clears old discoveries")
	AdventureSnapshot.restore(game, saved)
	check(game.map.exploration.visited(Vector2.ZERO), "save restores exploration")
	game.set_process_unhandled_input(false)
	key(KEY_M)
	check(game.map.expanded and not game.shooting_view.local_input.enabled, "M opens and blocks local controls with solo handler disabled")
	key(KEY_ESCAPE)
	check(not game.map.expanded and not app.menu.visible, "Escape closes map before pause")
	check(game.shooting_view.local_input.enabled, "close restores input")
	game.chat.view.set_editing(true)
	key(KEY_M)
	check(not game.map.expanded, "typing M does not open map")
	game.chat.view.set_editing(false)
	var roster := CoopRoster.new()
	var room := PlaytestRoom.new()
	roster.room = room
	room.local_key = "me"
	room.names = {"friend": "Sprout"}
	var friend := preload("res://game/player/player.tscn").instantiate()
	game.add_child(friend)
	friend.set_physics_process(false)
	friend.position = Vector3(-20, 0, 15)
	roster.actors = {"me": game.player, "friend": friend}
	game.map.roster = roster
	check(game.map.markers().size() == 6, "party has one local marker and friend")
	friend.position = Vector3(25, 0, -25)
	var rows: Array[Dictionary] = game.map.markers()
	check(not game.map.exploration.visited(Vector2(25, -25)), "friends do not reveal remote terrain")
	check(rows.back().point == Vector2(25, -25) and rows.back().label == "Sprout", "friend label and replicated movement are live")
	if "--preview" in OS.get_cmdline_user_args():
		game.map.restore_exploration("")
		for x in range(0, 31, 2): game.map.exploration.reveal(Vector2(x, 4))
		game.map._refresh_fog()
		game.player.position = Vector3(20, 0, 4)
		game.map._process(0)
		game.map.view._layout()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-minimap.png")
		key(KEY_M)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-map.png")
		root.size = Vector2i(960, 540)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-map-small.png")
		canvas.reset_overview()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-map-overview.png")
		game.map.close()
		for npc: Node3D in game.world.map_npcs.values():
			game.map.exploration.reveal(game.map._map_position(npc))
	roster.actors.erase("friend")
	friend.queue_free()
	check(game.map.markers().size() == 5, "departed friend removed")
	key(KEY_M)
	app._input_enabled(false)
	check(not game.map.expanded and not game.shooting_view.local_input.enabled, "pause closes map without unlocking controls")
	game.map.roster = null
	roster.free()
	room.free()
	app.queue_free()
	await process_frame
	print("Map: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
