class_name DungeonPressView
extends CanvasLayer
## Station controls emit intent; the host owns timing and certification.

signal action_requested(action: String, object_id: String)
signal closed

var _accessible: bool = false
var _preset: Button
var _certificates: Label
var _instructions: Label
var _modern_ready: bool = false
var _other_operator: bool = false
var _trial_active: bool = false
var _timing_running: bool = false
var _active: bool = false
var _modern: bool = false
var _selected: String = ""
var _prior_focus: WeakRef
var _status: Label
var _gauge: ProgressBar
var _band: Panel
var _buttons: Array[Button] = []

func _ready() -> void:
	layer = 20
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	MenuStyle.label(column, "TOFU PRESS", 21)
	_instructions = MenuStyle.paragraph(column, "")
	_certificates = MenuStyle.paragraph(column, "Certified: Soft [ ] · Firm [ ] · Extra-firm [ ]")
	_status = MenuStyle.paragraph(column, "")
	_gauge = ProgressBar.new()
	_gauge.min_value = 0
	_gauge.max_value = 100
	_gauge.custom_minimum_size = Vector2(450, 28)
	column.add_child(_gauge)
	_band = Panel.new()
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = Color(1, 1, 1, 0.15)
	band_style.border_color = Color.BLACK
	band_style.set_border_width_all(3)
	_band.add_theme_stylebox_override("panel", band_style)
	_gauge.add_child(_band)
	_band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var samples := HBoxContainer.new()
	column.add_child(samples)
	for entry in [["Choose soft sample", "soft"], ["Choose firm sample", "firm"]]:
		_buttons.append(MenuStyle.button(samples, entry[0], _choose.bind(entry[1])))
	var grips := HBoxContainer.new()
	column.add_child(grips)
	for index in 3:
		_buttons.append(MenuStyle.button(grips, "Place stone %d" % (index + 1), _emit.bind("stone", "stone_%d" % (index + 1))))
	_buttons.append(MenuStyle.button(column, "Start press", _emit.bind("start", "")))
	_buttons.append(MenuStyle.button(column, "Lift / release", _emit.bind("release", "")))
	_buttons.append(MenuStyle.button(column, "Stop gauge", _emit.bind("stop", "")))
	_buttons.append(MenuStyle.button(column, "Back", _cancel))
	_preset = MenuStyle.button(column, "Timing: Standard", _request_preset)
	set_process(false)

func open(modern: bool) -> void:
	if _active: return
	var focused := get_viewport().gui_get_focus_owner()
	_prior_focus = weakref(focused) if focused != null else null
	_active = true
	_modern = modern
	_selected = ""
	_trial_active = false
	_timing_running = false
	_other_operator = false
	visible = true
	_gauge.visible = modern
	_buttons[0].visible = not modern
	_buttons[1].visible = not modern
	for index in range(2, 5): _buttons[index].visible = not modern
	_buttons[6].visible = not modern
	_buttons[7].visible = modern
	_buttons[5].text = "Start pressure" if modern else "Begin selected trial"
	_instructions.text = "Extra-firm: start pressure, then stop in the marked gauge band.\nFirst certify soft and firm at the stone press." if modern else "Soft: 1 stone for 3 seconds. Firm: 2 stones for 5 seconds.\nChoose → begin trial → place stones → lift. The timer starts when the required stones are placed."
	_status.text = "Start the gauge; stop in the marked 82–90 band." if modern else "Choose soft or firm, place stones, then lift at the correct time."
	MenuStyle.focus_later(_buttons[5] if modern else _buttons[0])

func is_modern() -> bool:
	return _modern

func _cancel() -> void:
	if not _active: return
	action_requested.emit("abandon", "")
	close()

func close() -> void:
	if not _active: return
	_active = false
	visible = false
	if _prior_focus != null:
		var previous: Control = _prior_focus.get_ref()
		if previous != null and previous.is_inside_tree() and previous.is_visible_in_tree():
			MenuStyle.focus_later(previous)
	_prior_focus = null
	closed.emit()

func present(stones: int, seconds: float, gauge_value: float, message: String = "", accessible: bool = false) -> void:
	if not _active: return
	_accessible = accessible
	_preset.text = "Timing: Wider windows" if accessible else "Timing: Standard"
	_gauge.value = clampf(gauge_value, 0.0, 100.0)
	_band.anchor_left = 0.78 if accessible else 0.82
	_band.anchor_right = 0.94 if accessible else 0.90
	if not message.is_empty(): _status.text = message
	elif _modern:
		_status.text = "Gauge %.1f · stop at %s" % [gauge_value, "78–94" if accessible else "82–90"] if _trial_active else "Ready for extra-firm. Press Start pressure." if _modern_ready else "Certify soft and firm at the stone press first."
	else:
		var selected: String = _selected.capitalize() if not _selected.is_empty() else "No sample selected"
		var target: int = 3 if _selected == "soft" else 5
		var count: int = 1 if _selected == "soft" else 2
		_status.text = "%s · %d / %d stones
Elapsed %.2fs · lift at %ds (±%.2fs)" % [selected, stones, count, seconds, target, 1.25 if accessible else 0.75] if not _selected.is_empty() else "Choose a sample, then begin its trial."
		if _trial_active and not _timing_running: _status.text += "\nPlace the required stones to start the timer."
		elif _trial_active: _status.text += "\nTimer running — press Lift / release to finish."
	if _other_operator: _status.text = "Another operator is using this press. Wait for their sample to finish."

func present_trial(sample: String, placed: Array[String], active: bool, timing: bool, certificates: Array[bool], owned: bool = true) -> void:
	if not _active or certificates.size() != 3: return
	if active and not sample.is_empty(): _selected = sample
	var marks: Array[String] = []
	for index in 3: marks.append("✓" if certificates[index] else " ")
	_certificates.text = "Certified: Soft [%s] · Firm [%s] · Extra-firm [%s]" % marks
	_modern_ready = certificates[0] and certificates[1] and not certificates[2]
	for index in 2: _buttons[index].disabled = active or certificates[index]
	for index in 3:
		_buttons[index + 2].disabled = not active or placed.has("stone_%d" % (index + 1))
	_buttons[5].disabled = active or (not _modern and _selected.is_empty()) or (_modern and not _modern_ready)
	_buttons[6].disabled = not active or not timing
	_buttons[7].disabled = not active
	if active and not _trial_active:
		MenuStyle.focus_later(_buttons[7] if _modern else _buttons[2])
	elif active and timing and not _timing_running and not _modern:
		MenuStyle.focus_later(_buttons[6])
	elif not active and _trial_active and not _modern:
		_selected = ""
		MenuStyle.focus_later(_buttons[1] if certificates[0] else _buttons[0])
	_trial_active = active
	_timing_running = timing
	_other_operator = active and not owned
	_preset.disabled = _other_operator
	if _other_operator:
		for index in 8: _buttons[index].disabled = true

func _request_preset() -> void:
	if not _active: return
	action_requested.emit("preset", "standard" if _accessible else "accessible")

func _choose(sample: String) -> void:
	if _trial_active or _other_operator: return
	_selected = sample
	_buttons[5].disabled = false
	MenuStyle.focus_later(_buttons[5])
	_status.text = "%s sample selected. Start, place stones, then lift." % sample.capitalize()

func _emit(action: String, object_id: String) -> void:
	if not _active or _other_operator: return
	if action == "start" and not _modern:
		if _selected.is_empty():
			_status.text = "Choose a sample first."
			return
		object_id = _selected
	action_requested.emit(action, object_id)

func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
