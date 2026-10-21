class_name BattleHUD
extends CanvasLayer
## Receives formatted match values and emits user intentions.

signal leave_requested
signal spectate_requested
var readout: Label
var controls_hint: Label
var equipment: Label
var result: Label
var teammate: Label
var feed: Label
var radar: BattleRadar
var exit_panel: PanelContainer
var _root: Control
var _header: PanelContainer
var _stack: VBoxContainer
var recovery_panel: BattleRecoveryPanel

func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var hint := MenuStyle.paragraph(_root, "1 / 2 weapons · LMB attack · RMB aim / special · F punch · E loot · R reload · 3 heal · Tab map")
	controls_hint = hint
	hint.add_theme_color_override("font_shadow_color", Color("102d29"))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 2)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 20
	hint.offset_right = -20
	hint.offset_top = -58
	hint.add_theme_font_size_override("font_size", 14)
	var header := PanelContainer.new()
	_header = header
	header.position = Vector2(16, 14)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_stylebox_override("panel", MenuStyle.panel(Color("153a35dc"), 12))
	_root.add_child(header)
	var stack := VBoxContainer.new()
	_stack = stack
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(stack)
	readout = MenuStyle.label(stack, "", 23, MenuStyle.SOY_GOLD)
	equipment = MenuStyle.label(stack, "", 18)
	for label: Label in [readout, equipment]: label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	equipment.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	teammate = MenuStyle.label(stack, "", 18, MenuStyle.MINT)
	teammate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teammate.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result = MenuStyle.label(stack, "", 26, MenuStyle.MINT)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	feed = MenuStyle.label(stack, "", 16)
	feed.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	radar = BattleRadar.new()
	_root.add_child(radar)
	radar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radar.offset_left = -204
	radar.offset_right = -24
	radar.offset_top = 20
	radar.offset_bottom = 200
	exit_panel = PanelContainer.new()
	_root.add_child(exit_panel)
	exit_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	exit_panel.offset_left = -210
	exit_panel.offset_right = 210
	exit_panel.offset_top = -90
	exit_panel.offset_bottom = 90
	exit_panel.add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK))
	var buttons := VBoxContainer.new()
	exit_panel.add_child(buttons)
	MenuStyle.button(buttons, "Resume match", func() -> void: exit_panel.hide())
	MenuStyle.button(buttons, "Next survivor", spectate_requested.emit)
	MenuStyle.button(buttons, "Leave Battle Royale", leave_requested.emit)
	exit_panel.hide()
	recovery_panel = BattleRecoveryPanel.new()
	_root.add_child(recovery_panel)
	recovery_panel.leave_requested.connect(leave_requested.emit)
	_root.resized.connect(_responsive)
	_responsive()

func display(data: Dictionary) -> void:
	readout.text = tr("Alive: %d / %d · KOs: %d · Storm %d · %ds") % [data.alive, data.get("total", 20), data.kills, data.stage, data.seconds]
	equipment.text = tr("HP %d · Armour %d · SP %d · %s · Magazine %d · Reload %.1fs · Food %d") % [data.hp, data.armour, data.get("sp", 100), tr(data.weapon), data.ammo, data.get("reload", 0.0), data.heals]
	if data.get("tank", -1) >= 0: equipment.text += tr(" · Milk tank %d") % data.tank
	if not str(data.get("special", "")).is_empty(): equipment.text += "\n" + str(data.special)
	teammate.text = str(data.get("team", ""))
	var deploying: bool = data.get("deploying", false)
	teammate.visible = not teammate.text.is_empty() and not deploying
	equipment.visible = not deploying
	result.text = data.result
	feed.text = data.feed
	result.visible = not result.text.is_empty()
	feed.visible = not feed.text.is_empty()
	_header.reset_size()
	radar.position_on_map = data.at
	radar.center = data.center
	radar.radius = data.radius
	radar.queue_redraw()

func toggle_map() -> void:
	radar.expanded = not radar.expanded
	_responsive()

func show_recovery(message: String) -> void:
	recovery_panel.display(message)
	if not message.is_empty(): exit_panel.hide()

func _responsive() -> void:
	var compact := _root.size.x < 900
	var box := _header.get_theme_stylebox("panel") as StyleBoxFlat
	box.set_content_margin_all(12 if compact else 20)
	_stack.add_theme_constant_override("separation", 4 if compact else 8)
	controls_hint.text = "B bag · I stats · E loot · 1/2 gear · 3–6 support · G/H mark" if compact else "B backpack · I match stats · E chest / loot · 1 / 2 weapons · 3–6 support · Q drop · R reload · Tab map · G route / H danger"
	_header.custom_minimum_size.x = minf(760, _root.size.x - 32)
	_header.size.x = _header.custom_minimum_size.x
	readout.add_theme_font_size_override("font_size", 17 if compact else 23)
	equipment.add_theme_font_size_override("font_size", 14 if compact else 18)
	teammate.add_theme_font_size_override("font_size", 14 if compact else 18)
	result.add_theme_font_size_override("font_size", 18 if compact else 26)
	var width := minf(500, minf(_root.size.x - 48, _root.size.y - 80)) if radar.expanded else (128.0 if compact else 180.0)
	radar.anchor_top = 1 if compact and not radar.expanded else 0
	radar.anchor_bottom = radar.anchor_top
	radar.offset_left = -width - 24
	radar.offset_right = -24
	radar.offset_top = -width - 80 if compact and not radar.expanded else 20.0
	radar.offset_bottom = radar.offset_top + width
