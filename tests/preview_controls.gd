extends SceneTree
## Render desktop and forced-touch layouts with the actual project stretch rules.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var touch: TouchControls = scene.get_node("TouchControls")
	touch.force_visible = true
	root.add_child(scene)
	var hud: HUD = scene.get_node("HUD")
	touch.visible = false
	await _capture("desktop")
	hud.toggle_help()
	touch.visible = true
	await _capture("touch")
	root.size = Vector2i(1560, 720)
	await _capture("wide-touch")
	root.size = Vector2i(960, 720)
	await _capture("tablet-touch")
	scene.queue_free()
	await process_frame
	quit()

func _capture(label: String) -> void:
	for frame in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("/tmp/tofufu-controls-" + label + ".png")
	assert(error == OK)
