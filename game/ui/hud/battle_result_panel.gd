class_name BattleResultPanel
extends PanelContainer
## Scrollable round recap; the app supplies results, career and rematch readiness.

signal replay_requested
signal leave_requested
var heading: Label
var details: Label
var progress: Label
var status: Label
var replay: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	add_child(stack)
	heading = MenuStyle.label(stack, "", 24, MenuStyle.SOY_GOLD)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	details = MenuStyle.paragraph(body, "")
	progress = MenuStyle.paragraph(body, "")
	status = MenuStyle.paragraph(body, "")
	for label: Label in [heading, details, progress, status]: label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	replay = MenuStyle.button(stack, "Ready for rematch", replay_requested.emit)
	var actions := HBoxContainer.new()
	stack.add_child(actions)
	MenuStyle.button(actions, "Spectate", hide).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuStyle.button(actions, "Leave Battle Royale", leave_requested.emit).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	get_viewport().size_changed.connect(_responsive)
	_responsive()
	hide()

func _responsive() -> void:
	var area := get_viewport_rect().size
	var dimensions := Vector2(minf(620, area.x - 32), minf(490, area.y - 32))
	offset_left = -dimensions.x * 0.5
	offset_right = dimensions.x * 0.5
	offset_top = -dimensions.y * 0.5
	offset_bottom = dimensions.y * 0.5
	(get_theme_stylebox("panel") as StyleBoxFlat).set_content_margin_all(12 if area.y < 500 else 20)
	heading.add_theme_font_size_override("font_size", 18 if area.y < 500 else 24)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
