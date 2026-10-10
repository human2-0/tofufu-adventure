class_name LaunchMenu
extends Control

signal new_game
signal continue_game
signal coop
signal settings
signal resume_game
signal save_game
signal return_title
signal quit_game

var content: VBoxContainer
var heading: Label
var subtitle: Label
var note: Label
var _home: VBoxContainer
var _home_frame: MarginContainer
var _page: PanelContainer
var _margin: MarginContainer
var _scroll: ScrollContainer
var _brand: Label
var _eyebrow: Label
var _description: Label
var _adventure: Label
var _actions: VBoxContainer
var _page_width: float = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = MenuStyle.make_theme()
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = MarginContainer.new()
	add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := VBoxContainer.new()
	_margin.add_child(layout)
	MenuStyle.label(layout, "T O F U F U   /   A D V E N T U R E", 14, MenuStyle.MINT)
	_scroll = ScrollContainer.new()
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_scroll)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(row)
	_home_frame = MarginContainer.new()
	_home_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_home_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# Scroll containers clip descendants, including focus glows and button shadows.
	for side in ["left", "right", "top", "bottom"]:
		_home_frame.add_theme_constant_override("margin_" + side, 0 if side == "top" else 14)
	row.add_child(_home_frame)
	_home = VBoxContainer.new()
	_home_frame.add_child(_home)
	_page = PanelContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_page)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.add_child(content)
	note = MenuStyle.paragraph(layout, "")
	resized.connect(_responsive)
	show_home()
	_responsive()

func clear_page(title: String, description: String) -> VBoxContainer:
	set_page_width(0)
	_home_frame.hide()
	_page.show()
	_clear(content)
	heading = MenuStyle.label(content, title, 32)
	subtitle = MenuStyle.paragraph(content, description)
	_scroll.scroll_vertical = 0
	_responsive()
	return content

func set_page_width(width: float) -> void:
	_page_width = width
	_page.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if width > 0 else Control.SIZE_EXPAND_FILL
	_responsive()

func show_home(paused: bool = false, can_save: bool = true) -> void:
	_page.hide()
	_home_frame.show()
	_clear(_home)
	_eyebrow = MenuStyle.label(_home, "YOUR NEXT CHAPTER", 13, MenuStyle.SOY_GOLD)
	_brand = MenuStyle.label(_home, "Tofufu", 76)
	_adventure = MenuStyle.label(_home, "A D V E N T U R E", 22, MenuStyle.MINT)
	_description = MenuStyle.paragraph(_home, "A little bean. A world of possibilities.\nExplore, grow and adventure together.")
	var buttons := VBoxContainer.new()
	_actions = buttons
	buttons.custom_minimum_size.x = 0
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home.add_child(buttons)
	var first: Button
	if paused:
		first = MenuStyle.button(buttons, "Resume adventure   →", resume_game.emit, MenuIcons.ARROW)
		if can_save: MenuStyle.button(buttons, "Save adventure", save_game.emit, MenuIcons.BOOK)
		MenuStyle.button(buttons, "Settings", settings.emit, MenuIcons.SETTINGS)
		MenuStyle.button(buttons, "Save & return to title" if can_save else "Leave & return to title", return_title.emit, MenuIcons.EXIT)
	else:
		first = MenuStyle.button(buttons, "New adventure   →", new_game.emit, MenuIcons.SPROUT)
		first.add_theme_stylebox_override("normal", MenuStyle.button_box("primary"))
		MenuStyle.button(buttons, "Continue adventure", continue_game.emit, MenuIcons.BOOK)
		MenuStyle.button(buttons, "Play with friends", coop.emit, MenuIcons.FRIENDS)
		var utilities := VBoxContainer.new()
		buttons.add_child(utilities)
		for item in [["Settings", settings.emit, MenuIcons.SETTINGS], ["Quit", quit_game.emit, MenuIcons.EXIT]]:
			var button := MenuStyle.button(utilities, item[0], item[1], item[2])
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyle.focus_later(first)
	note.text = "Esc / Start · Resume     /     Progress autosaves every minute" if paused else "SOLO & CO-OP   /   Your adventure, your pace   /   Playtest"
	_scroll.scroll_vertical = 0
	_responsive()

func _responsive() -> void:
	var compact := size.y < 460
	var padding: int = 16 if compact else (24 if size.x < 1000 else 48)
	for side in ["left", "right", "top", "bottom"]:
		_margin.add_theme_constant_override("margin_" + side, padding)
	_page.custom_minimum_size.x = minf(_page_width, size.x - padding * 2 - 12) if _page_width > 0 else 0
	if is_instance_valid(heading): heading.add_theme_font_size_override("font_size", 24 if compact else 32)
	note.add_theme_font_size_override("font_size", 12 if compact else 16)
	if not is_instance_valid(_brand): return
	_home.custom_minimum_size.x = minf(380, size.x - padding * 2 - 40)
	_brand.add_theme_font_size_override("font_size", 32 if compact else (58 if size.y < 650 else 76))
	_eyebrow.visible = not compact
	_description.visible = not compact
	_adventure.add_theme_font_size_override("font_size", 16 if compact else 22)
	_home.add_theme_constant_override("separation", 4 if compact else 12)
	_actions.add_theme_constant_override("separation", 4 if compact else 12)
	for action: Control in _actions.get_children():
		if action is Button: _fit_button(action, compact)
		elif action is Container:
			action.add_theme_constant_override("separation", 4 if compact else 12)
			for button: Control in action.get_children():
				_fit_button(button as Button, compact)

func _fit_button(button: Button, compact: bool) -> void:
	MenuStyle.fit_button(button, compact)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if compact:
		button.custom_minimum_size.y = 32
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var box := button.get_theme_stylebox(state) as StyleBoxFlat
			box.content_margin_top = 3
			box.content_margin_bottom = 3

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
