class_name ChatView
extends CanvasLayer
## Text composer and bounded plain-text history. Supports compact and expanded modes.

signal submitted(message: String, yell: bool)
signal editing_changed(active: bool)
var editing: bool = false
var available: bool = true
var is_compact: bool = true
var history: Array[String] = []
var entry: LineEdit
var yell: Button
var microphone: CheckButton
var listening: CheckButton
var status: Label
var _toggle_btn: Button
var _history: RichTextLabel
var _voice: HBoxContainer
var _composer: HBoxContainer
var _panel: PanelContainer

func _ready() -> void:
	layer = 8
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.offset_left = 18
	_panel.offset_bottom = -116
	add_child(_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.16, 0.55)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.border_color = Color(0.55, 0.8, 0.72, 0.28)
	style.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_panel.add_child(column)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)

	status = Label.new()
	status.text = "NEARBY · Enter to chat"
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("dbe8c1"))
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status)

	_toggle_btn = Button.new()
	_toggle_btn.text = "▲ Chat"
	_toggle_btn.tooltip_text = "Toggle compact / full chat view"
	_toggle_btn.flat = true
	_toggle_btn.add_theme_font_size_override("font_size", 11)
	_toggle_btn.add_theme_color_override("font_color", Color("b8d7dd"))
	_toggle_btn.pressed.connect(toggle_compact)
	header.add_child(_toggle_btn)

	_history = RichTextLabel.new()
	_history.custom_minimum_size.y = 100
	_history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history.bbcode_enabled = false
	_history.scroll_following = true
	_history.add_theme_font_size_override("normal_font_size", 13)
	column.add_child(_history)

	_voice = HBoxContainer.new()
	column.add_child(_voice)
	microphone = CheckButton.new()
	microphone.text = "Mic · hold V"
	microphone.tooltip_text = "Enable microphone, then hold V to talk within 12 units."
	microphone.disabled = true
	_voice.add_child(microphone)
	listening = CheckButton.new()
	listening.text = "Listen"
	listening.button_pressed = true
	_voice.add_child(listening)

	_composer = HBoxContainer.new()
	column.add_child(_composer)
	entry = LineEdit.new()
	entry.max_length = 240
	entry.placeholder_text = "Say something nearby…"
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_composer.add_child(entry)
	yell = Button.new()
	yell.text = "Yell"
	yell.icon = preload("res://game/chat/yell.svg")
	yell.toggle_mode = true
	yell.tooltip_text = "Yell reaches 36 units (normal chat: 12)."
	_composer.add_child(yell)
	yell.toggled.connect(func(active: bool) -> void:
		yell.modulate = Color("ffdb8a") if active else Color.WHITE
		entry.placeholder_text = "Yell farther…" if active else "Say something nearby…"
		entry.grab_focus())
	entry.text_submitted.connect(_submit)
	_apply_compact()

func set_compact(active: bool) -> void:
	is_compact = active
	_apply_compact()

func toggle_compact() -> void:
	set_compact(not is_compact)

func _apply_compact() -> void:
	var show_full: bool = not is_compact or editing
	_history.visible = show_full
	_voice.visible = show_full
	_composer.visible = editing
	_toggle_btn.text = "▼" if show_full else "▲ Chat"
	if show_full:
		_panel.offset_top = -340
		_panel.offset_right = 390
	else:
		_panel.offset_top = -146
		_panel.offset_right = 260

func _input(event: InputEvent) -> void:
	if not available: return
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if event.pressed and _panel.get_global_rect().has_point(event.position):
			editing_changed.emit(true)
		elif not event.pressed:
			editing_changed.emit(editing)
		return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		if editing: _submit(entry.text)
		else: set_editing(true)
		get_viewport().set_input_as_handled()
	elif editing and event.keycode == KEY_ESCAPE:
		set_editing(false)
		get_viewport().set_input_as_handled()

func set_editing(active: bool) -> void:
	editing = active
	_apply_compact()
	if active: entry.grab_focus()
	else:
		entry.clear()
		entry.release_focus()
		yell.set_pressed_no_signal(false)
		yell.modulate = Color.WHITE
		entry.placeholder_text = "Say something nearby…"
	editing_changed.emit(active)

func _submit(value: String) -> void:
	var message := ProximityRules.clean(value)
	if not message.is_empty(): submitted.emit(message, yell.button_pressed)
	set_editing(false)

func show_message(speaker: String, message: String, shouted: bool) -> void:
	history.append("%s%s: %s" % [speaker, " [YELL]" if shouted else "", message])
	if history.size() > 50: history.pop_front()
	_history.text = "\n".join(history)
	if is_compact and not editing:
		_toggle_btn.text = "▲ [Msg!]"
