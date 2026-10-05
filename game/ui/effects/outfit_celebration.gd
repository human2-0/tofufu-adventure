class_name OutfitCelebration
extends CanvasLayer
## Set-completion banner remains visible above an open inventory window.

static func spawn(parent: Node, title: String, details: String, accent: Color) -> void:
	for child in parent.get_children():
		if child is OutfitCelebration: child.queue_free()
	var effect := OutfitCelebration.new()
	effect.layer = 20
	parent.add_child(effect)
	effect._present(title, details, accent)

func _present(title: String, details_text: String, accent: Color) -> void:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	var flash := ColorRect.new()
	flash.color = Color(accent.r, accent.g, accent.b, 0.13)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(flash)
	flash.create_tween().tween_property(flash, "modulate:a", 0.0, 0.75)
	var banner := PanelContainer.new()
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.offset_left = -350
	banner.offset_right = 350
	banner.offset_top = 68
	banner.offset_bottom = 188
	banner.pivot_offset = Vector2(350, 60)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17332df2")
	style.border_color = accent
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(12)
	banner.add_theme_stylebox_override("panel", style)
	canvas.add_child(banner)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 4)
	banner.add_child(column)
	var heading := Label.new()
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.text = "✦ %s set complete! ✦" % title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", accent)
	column.add_child(heading)
	var details := Label.new()
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.text = details_text
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_theme_font_size_override("font_size", 15)
	details.add_theme_color_override("font_color", Color("e9f4dd"))
	column.add_child(details)
	banner.modulate.a = 0.0
	banner.scale = Vector2.ONE * 0.84
	var entrance := banner.create_tween().set_parallel(true)
	entrance.tween_property(banner, "modulate:a", 1.0, 0.32)
	entrance.tween_property(banner, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var center := Vector2(get_viewport().get_visible_rect().size.x * 0.5, 130)
	for index in 18:
		var spark := ColorRect.new()
		spark.color = accent if index % 3 != 0 else Color("fff3bb")
		spark.size = Vector2(6, 12)
		spark.pivot_offset = spark.size * 0.5
		spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(spark)
		var angle := index * TAU / 18.0
		spark.position = center + Vector2(cos(angle), sin(angle)) * 70.0
		var target := center + Vector2(cos(angle), sin(angle)) * 290.0
		var flight := spark.create_tween().set_parallel(true)
		flight.tween_property(spark, "position", target, 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flight.tween_property(spark, "modulate:a", 0.0, 0.82)
		flight.tween_property(spark, "rotation", angle + PI, 0.82)
	var cleanup := create_tween()
	cleanup.tween_interval(3.5)
	cleanup.tween_callback(queue_free)
