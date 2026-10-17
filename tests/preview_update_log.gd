extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GamePreferences.install_translations(self)
	var menu := LaunchMenu.new()
	root.add_child(menu)
	var flow := UpdateLogFlow.new()
	flow.menu = menu
	flow.go_back = menu.show_home
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.content_scale_size = dimensions
			root.size = dimensions
			flow.show_history()
			for frame in 10: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-updates-%s-%d.png" % [locale, dimensions.x])
			menu._scroll.scroll_vertical = 100000
			for frame in 4: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-updates-%s-%d-bottom.png" % [locale, dimensions.x])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	for paused in [false, true]:
		menu.show_home(paused)
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-updates-home-%s.png" % str(paused))
	menu.queue_free()
	await process_frame
	quit()
