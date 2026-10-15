class_name SoloArenaPanel
extends Control
## Solo challenge invitation and boss readout; only emits local user intents.

signal challenged
signal surrendered
var card: PanelContainer
var title: Label
var detail: Label
var health: ProgressBar
var challenge: Button
var leave: Button
var _confirm_until: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	card = PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	card.offset_left = -260
	card.offset_right = 260
	card.offset_top = 12
	card.offset_bottom = 164
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18322ff5")
	style.border_color = Color("e4b86c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)
	add_child(card)
	var box := VBoxContainer.new()
	card.add_child(box)
	title = MenuStyle.label(box, "DOFUFU · JADE DRAGON MASTER", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health = ProgressBar.new()
	health.custom_minimum_size.y = 22
	box.add_child(health)
	detail = MenuStyle.label(box, "", 14)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge = MenuStyle.button(box, "SOLO BATTLE · CHALLENGE DOFUFU", func() -> void: challenged.emit())
	leave = MenuStyle.button(box, "SURRENDER [F8]", _surrender)
	hide()

func present(phase: String, current: float, maximum: float, text: String) -> void:
	visible = phase != "idle"
	if not visible: return
	health.visible = phase in ["entry", "fight"]
	health.max_value = maximum
	health.value = current
	detail.text = text
	challenge.visible = phase == "invite"
	leave.visible = phase in ["entry", "fight"]
	if _confirm_until > 0.0 and Time.get_ticks_msec() * 0.001 > _confirm_until:
		_confirm_until = 0.0
		leave.text = "SURRENDER [F8]"

func _surrender() -> void:
	if _confirm_until == 0.0:
		_confirm_until = Time.get_ticks_msec() * 0.001 + 3.0
		leave.text = "CONFIRM SURRENDER"
	else:
		_confirm_until = 0.0
		leave.text = "SURRENDER [F8]"
		surrendered.emit()
	leave.release_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if leave.is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F8:
		_surrender()
		get_viewport().set_input_as_handled()
