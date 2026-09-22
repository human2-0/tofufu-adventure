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
var _page: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = MenuStyle.make_theme()
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	MenuStyle.label(layout, "✦ F U F U F A R M  /  CHAPTER 01 ✦", 14, MenuStyle.MUTED)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(row)
	_home = VBoxContainer.new()
	_home.custom_minimum_size.x = 380
	_home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_home)
	_page = PanelContainer.new()
	_page.custom_minimum_size.x = 640
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_page)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_page.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	note = MenuStyle.label(layout, "A little bean. A big world waiting.", 15)
	show_home()

func clear_page(title: String, description: String) -> VBoxContainer:
	_home.hide()
	_page.show()
	_clear(content)
	heading = MenuStyle.label(content, title, 32)
	subtitle = MenuStyle.paragraph(content, description)
	return content

func show_home(paused: bool = false, can_save: bool = true) -> void:
	_page.hide()
	_home.show()
	_clear(_home)
	MenuStyle.label(_home, "tofufu!", 76, MenuStyle.INK)
	MenuStyle.label(_home, "A D V E N T U R E  ·  BEANBOUND", 20, MenuStyle.LEAF)
	MenuStyle.label(_home, "A bean begins.", 20, MenuStyle.MUTED)
	var buttons := VBoxContainer.new()
	buttons.custom_minimum_size.x = 340
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_home.add_child(buttons)
	var first: Button
	if paused:
		first = MenuStyle.button(buttons, "Back to the meadow", resume_game.emit)
		if can_save:
			MenuStyle.button(buttons, "Save adventure", save_game.emit)
		MenuStyle.button(buttons, "Settings", settings.emit)
		MenuStyle.button(buttons, "Save & return to title" if can_save else "Leave & return to title", return_title.emit)
	else:
		first = MenuStyle.button(buttons, "New game     →", new_game.emit)
		first.add_theme_stylebox_override("normal", MenuStyle.button_box("focus"))
		MenuStyle.button(buttons, "Continue", continue_game.emit)
		MenuStyle.button(buttons, "Co-op mode", coop.emit)
		MenuStyle.button(buttons, "Settings", settings.emit)
		MenuStyle.button(buttons, "Quit", quit_game.emit)
	MenuStyle.focus_later(first)
	note.text = "Esc / Start · Menu     |     Progress autosaves every minute" if paused else "A little bean. A big world waiting.                         v0.1 · Playtest"

func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
