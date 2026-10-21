extends SceneTree
## Render the actual blocking recovery view at desktop and compact sizes.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	GamePreferences.install_translations(self)
	var background := ColorRect.new()
	background.color = Color("63936c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var hud := BattleHUD.new()
	root.add_child(hud)
	var values := {"alive": 13, "kills": 2, "stage": 3, "seconds": 26, "hp": 78, "armour": 25,
		"weapon": "Soybean gun", "ammo": 4, "reserve": 24, "heals": 1, "result": "", "feed": "",
		"at": Vector2.ZERO, "center": Vector2.ZERO, "radius": 140.0}
	for locale: String in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		for size: Vector2i in [Vector2i(1280, 720), Vector2i(640, 360)]:
			root.size = size
			root.content_scale_size = size
			for i in 3: await process_frame
			hud.display(values)
			hud.show_recovery(tr("Match paused · Finding a new host"))
			for i in 6: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://.codex/visualizations/2026/10/20/battle-migration/recovery-%s-%d.png" % [locale, size.x])
	print("Battle recovery preview complete")
	quit()
