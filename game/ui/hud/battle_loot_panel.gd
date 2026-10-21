class_name BattleLootPanel
extends CanvasLayer
## Choice list and stats text supplied by app composition; no gameplay mutation.
signal take_requested(id: int)
signal backpack_requested
signal close_requested
var heading: Label
var description: Label
var contents: VBoxContainer
var note: Label
var _panel: PanelContainer
var backpack_button: Button
var close_button: Button

func _ready() -> void:
	layer = 16
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_panel = PanelContainer.new()
	root.add_child(_panel)
	_panel.add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK))
	var stack := VBoxContainer.new()
	_panel.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	heading = MenuStyle.label(top, "", 24, MenuStyle.SOY_GOLD)
	heading.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_button = MenuStyle.button(top, "Backpack · B", backpack_requested.emit)
	close_button = MenuStyle.button(top, "Close", close_requested.emit)
	description = MenuStyle.paragraph(stack, "")
	description.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	contents = VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contents)
	note = MenuStyle.paragraph(stack, "")
	note.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	get_viewport().size_changed.connect(_fit)
	_fit()
	hide()

func display(title: String, text: String, rows: Array) -> void:
	heading.text = title
	description.text = text
	for child in contents.get_children():
		contents.remove_child(child)
		child.queue_free()
	for row: Dictionary in rows:
		var line := HBoxContainer.new()
		contents.add_child(line)
		var icon := TextureRect.new()
		icon.texture = row.get("icon")
		icon.visible = icon.texture != null
		icon.custom_minimum_size = Vector2(42, 42)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		line.add_child(icon)
		var label := MenuStyle.paragraph(line, str(row.label))
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.add_theme_color_override("font_color", row.get("color", Color.WHITE))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if row.has("id"):
			var button := MenuStyle.button(line, "Take", take_requested.emit.bind(int(row.id)))
			button.disabled = not row.get("enabled", true)
	show()
	# Refresh retained toolbar canvases after the layer is reopened or resized.
	backpack_button.queue_redraw()
	close_button.queue_redraw()

func _fit() -> void:
	var size := get_viewport().get_visible_rect().size
	_panel.position = Vector2(maxf(12, (size.x - 650) / 2), 12)
	_panel.size = Vector2(minf(650, size.x - 24), size.y - 24)
