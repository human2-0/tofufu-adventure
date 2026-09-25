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
	check(game.map.markers().size() == 5, "three NPCs, factory and local player mapped offline")
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
	check(canvas.project_point(canvas.bounds.position).is_equal_approx(canvas.map_rect().position), "negative Z is north")
	check(canvas.bounds.has_point(Vector2(40, 152)), "map includes the expanded desert crossing")
	check(canvas.bounds.has_point(Vector2(40, 320)), "map includes expanded southern jungle")
	check(canvas.bounds.has_point(Vector2(-40, -156)), "map includes expanded northern underwater world")
	check(canvas.bounds.has_point(Vector2(40, -320)), "map includes expanded northern frozen land")
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
	check(rows.back().point == Vector2(25, -25) and rows.back().label == "Sprout", "friend label and replicated movement are live")
	if "--preview" in OS.get_cmdline_user_args():
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
		game.map.close()
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
