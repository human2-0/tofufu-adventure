class_name MapView
extends CanvasLayer
## Responsive atlas shell; emits intent without owning gameplay or actors.

signal toggle_requested
signal mini_zoom_changed(value: float)
var mini := MapCanvas.new()
var full := MapCanvas.new()
var overlay := ColorRect.new()
var expand_button := MangaButton.new()
var close_button := MangaButton.new()
var _root := Control.new()
var navigation := HBoxContainer.new()
var mini_navigation := HBoxContainer.new()
var zoom_out := Button.new()
var zoom_in := Button.new()

func _ready() -> void:
	layer = 8
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = MenuStyle.make_theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.add_child(mini)
	mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_button.text = "Map [M] · Expand"
	expand_button.pressed.connect(toggle_requested.emit)
	_root.add_child(expand_button)
	_build_mini_controls()
	_build_overlay()
	_root.resized.connect(_layout)
	_layout()

func _build_mini_controls() -> void:
	_root.add_child(mini_navigation)
	mini_navigation.add_theme_constant_override("separation", 4)
	for button in [zoom_out, zoom_in]:
		button.text = "−" if button == zoom_out else "+"
		button.tooltip_text = "Zoom out" if button == zoom_out else "Zoom in"
		button.custom_minimum_size = Vector2(30, 28)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 18)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("e6ddbd") if state == "hover" else Color("fff7dc")
			box.border_color = Color("23473d")
			box.set_border_width_all(1)
			box.set_corner_radius_all(5)
			box.content_margin_left = 4
			box.content_margin_right = 4
			box.content_margin_top = 2
			box.content_margin_bottom = 2
			button.add_theme_stylebox_override(state, box)
		mini_navigation.add_child(button)
		button.pressed.connect(func() -> void: set_mini_zoom(mini.zoom * (1.25 if button == zoom_in else 0.8)))

func _build_overlay() -> void:
	overlay.color = Color("102a25f2")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(overlay)
	overlay.add_child(full)
	full.expanded = true
	full.mouse_filter = Control.MOUSE_FILTER_STOP
	var title := Label.new()
	title.text = "FUFUFARM · WORLD MAP"
	title.add_theme_color_override("font_color", Color("fff7dc"))
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 22)
	overlay.add_child(title)
	var legend := Label.new()
	legend.add_theme_color_override("font_color", Color("fff7dc"))
	legend.add_theme_font_size_override("font_size", 14)
	legend.text = "▲ You / look direction    ● Friends    ■ Discovered NPCs\nDrag to explore · Scroll to zoom · Dark sky = unvisited"
	legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	legend.position = Vector2(24, -58)
	overlay.add_child(legend)
	close_button.text = "Close map · Esc"
	close_button.pressed.connect(toggle_requested.emit)
	overlay.add_child(close_button)
	overlay.add_child(navigation)
	for caption in ["−", "+", "Overview"]:
		var button := Button.new()
		button.text = caption
		navigation.add_child(button)
		if caption == "Overview": button.pressed.connect(full.reset_overview)
		else: button.pressed.connect(func() -> void: full.zoom_at(full.size * 0.5, 1.5 if caption == "+" else 1.0 / 1.5))
	overlay.hide()

func _layout() -> void:
	var viewport_size := _root.size
	var side := minf(176, viewport_size.y * 0.27)
	mini.position = Vector2(16, 90)
	mini.size = Vector2.ONE * side
	expand_button.position = Vector2(16, 92 + side)
	expand_button.size = Vector2(side, 30)
	mini_navigation.position = mini.position + Vector2(side - 68, side - 34)
	full.position = Vector2(24, 58)
	full.size = Vector2(maxf(1, viewport_size.x - 48), maxf(1, viewport_size.y - 130))
	close_button.position = Vector2(viewport_size.x - 182, 14)
	close_button.size = Vector2(158, 34)
	navigation.position = Vector2(viewport_size.x - 220, viewport_size.y - 50)
	mini.queue_redraw()
	full.queue_redraw()

func set_expanded(value: bool) -> void:
	overlay.visible = value
	if value:
		full.zoom = 6.0
		full.center = mini.center
		full._clamp_center()
		full.queue_redraw()
		close_button.grab_focus()
	else: close_button.release_focus()

func present(markers: Array[Dictionary]) -> void:
	mini.markers = markers
	full.markers = markers
	mini.queue_redraw()
	if overlay.visible: full.queue_redraw()

func set_mini_zoom(value: float) -> void:
	mini.zoom = clampf(value, 0.5, 2.5)
	zoom_out.disabled = mini.zoom <= 0.5
	zoom_in.disabled = mini.zoom >= 2.5
	mini.queue_redraw()
	mini_zoom_changed.emit(mini.zoom)
