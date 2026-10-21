extends SceneTree
## Native bilingual CPU controls and keyboard-reachable compact lobby actions.

const OUTPUT := ".codex/visualizations/2026/10/20/battle-fifty-cpus"

func _initialize() -> void:
	call_deferred("_run")

func _shot(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://").path_join(OUTPUT).path_join(name + ".png"))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var app: Node = load("res://game/app/bootstrap/launch.tscn").instantiate()
	app.preferences.path = "user://battle-cpu-preview.cfg"
	root.add_child(app)
	await process_frame
	app.battle.show_lobby()
	var options: BattleCPUOptions = app.battle.panel.cpu_options
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		await _shot("lobby-" + locale)
	root.size = Vector2i(640, 360)
	root.content_scale_size = root.size
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		app.menu._scroll.scroll_vertical = 0
		await _shot("compact-top-" + locale)
		options.difficulty.grab_focus()
		await _shot("compact-options-" + locale)
		app.battle.panel.practice_button.grab_focus()
		await _shot("compact-practice-" + locale)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	app.menu._scroll.scroll_vertical = 0
	options.count.value = 50
	options.difficulty.select(2)
	options.difficulty.item_selected.emit(2)
	await _shot("maximum-pl")
	TranslationServer.set_locale("en")
	await _shot("maximum-en")
	TranslationServer.set_locale("pl")
	app.battle.panel.show_state("Waiting for players · Choose CPUs or invite friends", ["Friend", "Tofufu", "Bean", "Fufu"], false, true, true)
	options.display(50, 2, 50, 54, false)
	await _shot("guest-clamped-pl")
	TranslationServer.set_locale("en")
	await _shot("guest-clamped-en")
	app.battle.leave()
	app.queue_free()
	await process_frame
	quit()
