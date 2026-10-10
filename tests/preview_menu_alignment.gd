extends SceneTree
## Title/pause alignment at wide and compact sizes, including controller focus.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var menu := LaunchMenu.new()
	root.add_child(menu)
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		menu.show_home()
		await capture("title-%d" % dimensions.x)
		menu.show_home(true)
		await capture("pause-%d" % dimensions.x)
	menu.queue_free()
	await process_frame
	quit()
func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-menu-alignment-" + label + ".png")
