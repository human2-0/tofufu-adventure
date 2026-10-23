class_name BattleHUD
extends CanvasLayer
## Compact display-only HUD: graphic resources/loadout, small counters, optional help.
signal leave_requested
signal spectate_requested
signal graphics_requested
var readout: Label
var controls_hint: Label
var result: Label
var feed: Label
var radar: BattleRadar
var exit_panel: PanelContainer
var _root: Control
var _header: PanelContainer
var recovery_panel: BattleRecoveryPanel
var vitals: BattleVitalsHUD
var loadout: BattleLoadoutHUD
var zone: BattleZoneHUD
var _kills: Label
var _help: Button

func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_header = PanelContainer.new()
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_theme_stylebox_override("panel", MenuStyle.panel(BattleHUDIcons.INK, 9))
	_root.add_child(_header)
	var counters := HBoxContainer.new()
	counters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(counters)
	for symbol in [BattleHUDIcons.ALIVE, BattleHUDIcons.KO]:
		var icon := TextureRect.new()
		icon.texture = symbol
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(22, 22)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		counters.add_child(icon)
		var value := MenuStyle.label(counters, "", 20)
		value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if readout == null: readout = value
		else: _kills = value
	vitals = BattleVitalsHUD.new()
	_root.add_child(vitals)
	loadout = BattleLoadoutHUD.new()
	_root.add_child(loadout)
	zone = BattleZoneHUD.new()
	_root.add_child(zone)
	radar = BattleRadar.new()
	_root.add_child(radar)
	result = MenuStyle.paragraph(_root, "")
	result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feed = MenuStyle.paragraph(_root, "")
	feed.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	feed.add_theme_font_size_override("font_size", 12)
	feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_menu()
	recovery_panel = BattleRecoveryPanel.new()
	_root.add_child(recovery_panel)
	recovery_panel.leave_requested.connect(leave_requested.emit)
	_root.resized.connect(_responsive)
	_responsive()

func _build_menu() -> void:
	exit_panel = PanelContainer.new()
	_root.add_child(exit_panel)
	exit_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	exit_panel.offset_left = -200
	exit_panel.offset_right = 200
	exit_panel.offset_top = -145
	exit_panel.offset_bottom = 145
	exit_panel.add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK))
	var buttons := VBoxContainer.new()
	exit_panel.add_child(buttons)
	MenuStyle.button(buttons, "Resume match", exit_panel.hide)
	MenuStyle.button(buttons, "Graphics", graphics_requested.emit, MenuIcons.SETTINGS)
	MenuStyle.button(buttons, "Next survivor", spectate_requested.emit)
	MenuStyle.button(buttons, "Leave Battle Royale", leave_requested.emit)
	for button: Button in buttons.get_children(): MenuStyle.fit_button(button, true)
	controls_hint = MenuStyle.paragraph(buttons, "")
	controls_hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	controls_hint.add_theme_font_size_override("font_size", 12)
	_help_text()
	exit_panel.hide()
	_help = MenuStyle.button(_root, "?", func() -> void: exit_panel.visible = not exit_panel.visible)
	_help.tooltip_text = tr("Controls · F1")

func display(data: Dictionary) -> void:
	readout.text = "%d/%d" % [data.alive, data.get("total", 20)]
	_kills.text = str(data.kills)
	vitals.display(data)
	loadout.display(data)
	zone.display(data)
	var deploying: bool = data.get("deploying", false)
	vitals.visible = not deploying
	loadout.visible = not deploying
	zone.visible = not deploying
	result.text = data.result
	feed.text = data.feed
	result.visible = not result.text.is_empty()
	feed.visible = not feed.text.is_empty()
	radar.position_on_map = data.at
	radar.center = data.center
	radar.radius = data.radius
	radar.heading = data.get("view_heading", Vector2.UP)
	radar.queue_redraw()

func toggle_map() -> void:
	radar.expanded = not radar.expanded
	_responsive()

func show_recovery(message: String) -> void:
	recovery_panel.display(message)
	if not message.is_empty(): exit_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_help") and not event.is_echo():
		exit_panel.visible = not exit_panel.visible
		get_viewport().set_input_as_handled()

func _responsive() -> void:
	var compact := _root.size.x < 900
	_header.position = Vector2(12, 12)
	var style := _header.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_content_margin_all(7)
	_header.size = Vector2(146, 36)
	MenuStyle.fit_button(_help, true)
	_help.custom_minimum_size = Vector2(30, 30)
	_help.position = Vector2(164, 12)
	_help.size = Vector2(30, 34)
	vitals.size = Vector2(156, 66) if compact else Vector2(204, 80)
	vitals.position = Vector2(12, _root.size.y - vitals.size.y - 12)
	loadout.size = Vector2(276, 66) if compact else Vector2(346, 80)
	loadout.position = Vector2(_root.size.x - loadout.size.x - 12, _root.size.y - loadout.size.y - 12)
	zone.size = Vector2(200 if compact else 244, 52)
	zone.position = Vector2((_root.size.x - zone.size.x) * 0.5, 12)
	var width := minf(500, minf(_root.size.x - 40, _root.size.y - 40)) if radar.expanded else (100.0 if compact else 144.0)
	radar.position = (_root.size - Vector2.ONE * width) * 0.5 if radar.expanded else Vector2(_root.size.x - width - 12, 12)
	radar.size = Vector2.ONE * width
	feed.position = Vector2(12, 56)
	feed.size = Vector2(220 if compact else 340, 52)
	result.position = Vector2((_root.size.x - minf(460, _root.size.x - 32)) * 0.5, _root.size.y * 0.68)
	result.size = Vector2(minf(460, _root.size.x - 32), 60)

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and controls_hint != null:
		_help_text()
		if _help != null: _help.tooltip_text = tr("Controls · F1")

func _help_text() -> void:
	controls_hint.text = tr("B bag · I stats · E loot · 1/2 gear · 3–6 support · G/H mark") + "\n" + tr("C: camera · Middle click: direction · Mouse: orbit") + "\n" + tr("Round goals: 3 chests · 100 damage · 90s alive")
