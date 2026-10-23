class_name BattleGraphicsPanel
extends CanvasLayer
## Compact local settings; emits intent without pausing the shared match.

signal rendering_requested(limit: int, scale: float, sync: bool, adaptive: bool)
signal scenery_requested(distance: int, shadows: bool)
signal effect_requested(key: String, enabled: bool)
signal performance_requested
signal closed
var frame: PanelContainer
var fps: OptionButton
var resolution: OptionButton
var distance: OptionButton
var shadows: CheckButton
var adaptive: CheckButton
var sync: CheckButton
var message: Label
var close_button: Button
var _root: Control
var _fps_readout: Label
var _clock: float = 0.0
var effects: Dictionary[String, CheckButton] = {}
const LIMITS: Array[int] = [60, 120, 144, 0]
const SCALES: Array[float] = [0.5, 0.65, 0.75, 0.85, 1.0]
const DISTANCES: Array[int] = [160, 240, 360, 0]

func _ready() -> void:
	layer = 24
	var root := Control.new()
	_root = root
	root.theme = MenuStyle.make_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.06, 0.05, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	frame = PanelContainer.new()
	frame.add_theme_stylebox_override("panel", MenuStyle.panel(MenuStyle.INK, 12))
	root.add_child(frame)
	var layout := VBoxContainer.new()
	frame.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := MenuStyle.label(header, "Graphics", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fps_readout = MenuStyle.label(header, "", 14, MenuStyle.MINT)
	_fps_readout.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	close_button = MenuStyle.button(header, "Back", closed.emit, MenuIcons.ARROW)
	MenuStyle.fit_button(close_button, true)
	var note := MenuStyle.paragraph(layout, "Match continues while settings are open.")
	note.add_theme_font_size_override("font_size", 13)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	var preset := MenuStyle.button(body, "Performance preset", performance_requested.emit)
	MenuStyle.fit_button(preset, true)
	var hint := MenuStyle.paragraph(body, "Lower 3D resolution and scenery range for smoother play. Combat and cover stay active.")
	hint.add_theme_font_size_override("font_size", 13)
	fps = _picker(body, "Frame limit", ["60 FPS", "120 FPS", "144 FPS", "Uncapped"])
	resolution = _picker(body, "3D resolution", ["50%", "65%", "75%", "85%", "100%"])
	sync = _toggle(body, "VSync")
	adaptive = _toggle(body, "Adaptive 3D resolution")
	var apply_button := MenuStyle.button(body, "Apply rendering", func() -> void:
		rendering_requested.emit(LIMITS[fps.selected], SCALES[resolution.selected], sync.button_pressed, adaptive.button_pressed))
	MenuStyle.fit_button(apply_button, true)
	distance = _picker(body, "Scenery range", ["Near · 160 m", "Balanced · 240 m", "Far · 360 m", "Full map"])
	shadows = _toggle(body, "Dynamic shadows")
	distance.item_selected.connect(func(_index: int) -> void: _scenery())
	shadows.toggled.connect(func(_enabled: bool) -> void: _scenery())
	for key: String in ["wind", "fog", "motes", "puddles", "lightning", "thunder"]:
		var caption: String = {"wind": "Wind animation and leaves", "fog": "Atmospheric fog", "motes": "Fireflies and movement particles", "puddles": "Puddles and rain splashes", "lightning": "Lightning flashes", "thunder": "Thunder sounds"}[key]
		var option := _toggle(body, caption)
		option.toggled.connect(func(enabled: bool) -> void: effect_requested.emit(key, enabled))
		effects[key] = option
	message = MenuStyle.paragraph(layout, "Preferences are saved on this device.")
	message.add_theme_font_size_override("font_size", 12)
	root.resized.connect(_responsive)
	frame.minimum_size_changed.connect(_responsive)
	_responsive.call_deferred()
	hide()

func display(data: Dictionary) -> void:
	fps.select(maxi(0, LIMITS.find(int(data.limit))))
	resolution.select(maxi(0, SCALES.find(float(data.scale))))
	sync.set_pressed_no_signal(data.sync)
	adaptive.set_pressed_no_signal(data.adaptive)
	distance.select(maxi(0, DISTANCES.find(int(data.distance))))
	shadows.set_pressed_no_signal(data.shadows)
	for key in effects: effects[key].set_pressed_no_signal(data.effects[key])
	show()
	_responsive()
	_responsive.call_deferred()
	MenuStyle.focus_later(close_button)

func _picker(parent: Node, caption: String, options: Array) -> OptionButton:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := MenuStyle.label(row, caption, 15)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_stretch_ratio = 1.0
	var picker := OptionButton.new()
	for option: String in options: picker.add_item(option)
	row.add_child(picker)
	return picker

func _toggle(parent: Node, caption: String) -> CheckButton:
	var option := CheckButton.new()
	option.text = caption
	option.add_theme_font_size_override("font_size", 14)
	parent.add_child(option)
	return option

func _scenery() -> void:
	scenery_requested.emit(DISTANCES[distance.selected], shadows.button_pressed)

func _responsive() -> void:
	frame.size = Vector2(minf(570, _root.size.x - 24), minf(600, _root.size.y - 24))
	frame.position = (_root.size - frame.size) * 0.5

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_help")):
		closed.emit()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible: return
	_clock -= delta
	if _clock > 0: return
	_clock = 0.5
	_fps_readout.text = "%d FPS" % Engine.get_frames_per_second()
