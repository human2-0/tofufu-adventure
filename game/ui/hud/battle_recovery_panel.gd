class_name BattleRecoveryPanel
extends ColorRect
## Blocking recovery presentation; networking and recovery decisions stay outside UI.

signal leave_requested
var message: Label
var panel: PanelContainer

func _ready() -> void:
	color = Color(0.025, 0.06, 0.055, 0.78)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK, 20))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 15)
	panel.add_child(stack)
	message = MenuStyle.label(stack, "", 25, MenuStyle.SOY_GOLD)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var detail := MenuStyle.paragraph(stack, "Movement, combat and the storm are paused. Resuming from the last shared checkpoint.")
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	MenuStyle.button(stack, "Leave Battle Royale", leave_requested.emit)
	resized.connect(_responsive)
	_responsive()
	hide()

func display(text: String) -> void:
	message.text = text
	visible = not text.is_empty()

func _responsive() -> void:
	panel.custom_minimum_size.x = minf(520, size.x - 40)
	panel.size.x = panel.custom_minimum_size.x
	message.add_theme_font_size_override("font_size", 20 if size.x < 900 else 25)
