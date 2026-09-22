class_name MapView
extends CanvasLayer
## Responsive atlas shell; emits intent without owning gameplay or actors.

signal toggle_requested
var mini := MapCanvas.new()
var full := MapCanvas.new()
var overlay := ColorRect.new()
var expand_button := MangaButton.new()
var close_button := MangaButton.new()
var _root := Control.new()

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
	overlay.color = Color("102a25f2")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(overlay)
	overlay.add_child(full)
	full.expanded = true
	full.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = "FUFUFARM · WORLD MAP"
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 22)
	overlay.add_child(title)
	var legend := Label.new()
	legend.text = "● You (cream)    ● Friends (blue)    ■ NPCs (gold)\nNorth is up · Co-op keeps running while you browse"
	legend.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	legend.position = Vector2(24, -58)
	overlay.add_child(legend)
	close_button.text = "Close map · Esc"
	close_button.pressed.connect(toggle_requested.emit)
	overlay.add_child(close_button)
	overlay.hide()
	_root.resized.connect(_layout)
	_layout()

func _layout() -> void:
	var viewport_size := _root.size
	var side := minf(176, viewport_size.y * 0.27)
	mini.position = Vector2(16, 90)
	mini.size = Vector2.ONE * side
	expand_button.position = Vector2(16, 92 + side)
	expand_button.size = Vector2(side, 30)
	full.position = Vector2(24, 58)
	full.size = Vector2(maxf(1, viewport_size.x - 48), maxf(1, viewport_size.y - 130))
	close_button.position = Vector2(viewport_size.x - 182, 14)
	close_button.size = Vector2(158, 34)
	mini.queue_redraw()
	full.queue_redraw()

func set_expanded(value: bool) -> void:
	overlay.visible = value
	if value: close_button.grab_focus()
	else: close_button.release_focus()

func present(markers: Array[Dictionary]) -> void:
	mini.markers = markers
	full.markers = markers
	mini.queue_redraw()
	if overlay.visible: full.queue_redraw()
