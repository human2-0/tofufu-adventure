class_name DungeonCutterView
extends CanvasLayer
## Guide editing only; authority validates the submitted positions and widths.

signal cuts_committed(normalized_positions: PackedFloat32Array)
signal closed

const GUIDE_COUNT := 5
var _active := false
var _prior_focus: WeakRef
var _guides: Array[HSlider] = []
var _preview: Label
var _pieces: HBoxContainer
var _commit: Button

func _ready() -> void:
	layer = 20
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = MenuStyle.make_theme()
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(570, 0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	MenuStyle.label(column, "PRECISION CUTTING CARRIAGE", 20)
	MenuStyle.paragraph(column, "Move all five guides. Preview the positions, then commit the complete plan.")
	for index in GUIDE_COUNT:
		var row := HBoxContainer.new()
		column.add_child(row)
		MenuStyle.label(row, "Cut %d" % (index + 1), 16)
		var slider := HSlider.new()
		slider.min_value = 0.01
		slider.max_value = 0.99
		slider.step = 0.005
		slider.custom_minimum_size = Vector2(390, 32)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value = 0.1 + float(index) * 0.2
		slider.value_changed.connect(_update_preview.unbind(1))
		slider.gui_input.connect(_on_guide_input)
		row.add_child(slider)
		_guides.append(slider)
	_pieces = HBoxContainer.new()
	_pieces.custom_minimum_size = Vector2(510, 40)
	_pieces.add_theme_constant_override("separation", 2)
	column.add_child(_pieces)
	_preview = MenuStyle.paragraph(column, "")
	var actions := HBoxContainer.new()
	column.add_child(actions)
	MenuStyle.button(actions, "Preview cuts", _update_preview)
	_commit = MenuStyle.button(actions, "Commit cuts", _commit_cuts)
	MenuStyle.button(actions, "Back", close)
	_update_preview()

func open() -> void:
	if _active:
		return
	var focused := get_viewport().gui_get_focus_owner()
	_prior_focus = weakref(focused) if focused != null else null
	_active = true
	visible = true
	_commit.disabled = false
	MenuStyle.focus_later(_guides[0])

func close() -> void:
	if not _active:
		return
	_active = false
	visible = false
	if _prior_focus != null:
		var previous: Control = _prior_focus.get_ref()
		if previous != null and previous.is_inside_tree() and previous.is_visible_in_tree():
			MenuStyle.focus_later(previous)
	_prior_focus = null
	closed.emit()

func set_submission_available(available: bool) -> void:
	_commit.disabled = not available

func show_feedback(message: String) -> void:
	_preview.text = message
	_commit.disabled = false

func set_guides(positions: PackedFloat32Array) -> void:
	if positions.size() != GUIDE_COUNT:
		return
	for index in GUIDE_COUNT:
		_guides[index].value = clampf(positions[index], 0.01, 0.99)
	_update_preview()

func guide_positions() -> PackedFloat32Array:
	var positions := PackedFloat32Array()
	for slider in _guides:
		positions.append(float(slider.value))
	return positions

func _commit_cuts() -> void:
	if not _active or _commit.disabled:
		return
	_commit.disabled = true
	cuts_committed.emit(guide_positions())

func _update_preview() -> void:
	var parts: PackedStringArray = []
	for slider in _guides:
		parts.append("%.1f%%" % (slider.value * 100.0))
	_preview.text = "Guides at " + ", ".join(parts)
	for child: Node in _pieces.get_children():
		_pieces.remove_child(child)
		child.queue_free()
	var previous: float = 0.0
	for position: float in guide_positions():
		if position <= previous:
			_preview.text = "Guides cross or overlap. Adjust their order before committing."
			return
		_add_piece(position - previous)
		previous = position
	_add_piece(1.0 - previous)

func _add_piece(width: float) -> void:
	var piece := ColorRect.new()
	piece.color = Color(0.92, 0.86, 0.7)
	piece.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	piece.size_flags_stretch_ratio = width
	piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pieces.add_child(piece)

func _on_guide_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_update_preview()

func _unhandled_input(event: InputEvent) -> void:
	if _active and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
