extends SceneTree
## Render the real Polish menus, gameplay windows and compact layouts.

var app: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	app = load("res://game/app/bootstrap/launch.tscn").instantiate()
	preload("res://tests/lobby_test_transport.gd").inject(app)
	app.store.directory = "user://polish-preview"
	app.preferences.path = "user://polish-preview.cfg"
	app.preferences.fullscreen = false
	app.preferences.resolution = 1
	app.preferences.language = "pl"
	app.preferences.save()
	root.add_child(app)
	await _capture("landing")
	app.settings.show_settings()
	await _capture("settings")
	app.menu._scroll.scroll_vertical = 750
	await _capture("settings-controls")
	app.lobby.show_lobby()
	await _capture("lobby")
	app.menu.show_home()
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	await _capture("compact")
	app.settings.show_settings()
	await _capture("compact-settings")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await app._start(0, {"name": "Polska przygoda", "opening_complete": true})
	await _capture("hud")
	app.game.process_mode = Node.PROCESS_MODE_DISABLED
	app.game.inventory_window.open()
	await _capture("inventory")
	var button: InventorySlotButton = app.game.inventory_window._inv_buttons[0]
	app.game.inventory_window._tooltip.inspect(button, func() -> ItemStack: return ItemStack.new(MagicalTofufu.create(), 2))
	await _capture("tooltip")
	app.game.inventory_window.close()
	app.game.merchant.window.open()
	await _capture("shop")
	app.game.merchant.window.close()
	app.game.quest_giver._refresh_window()
	app.game.quest_giver.window.open()
	await _capture("quest")
	app.game.quest_giver.window.close()
	app.game.god_hunt.window.present(1, 37)
	app.game.god_hunt.window.show()
	await _capture("god-hunt")
	app.game.god_hunt.window.hide()
	app.game.seed_storage.window.open()
	await _capture("deposit")
	app.game.seed_storage.window.close()
	app.game.factory_dungeon.journal.open(TofuPuzzleClues.BRIEFING + "\n\n" + TofuPuzzleClues.NOTE, true)
	await _capture("factory-journal")
	app.store.remove_slot(0)
	DirAccess.remove_absolute(app.store.directory)
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-polish-" + label + ".png")
