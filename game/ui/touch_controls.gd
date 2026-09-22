class_name TouchControls
extends CanvasLayer
## Multitouch action surface. Aim follows travel and retains its last direction.

@export var force_visible: bool = false
var _surface: Node2D
var _buttons: Array[TouchScreenButton] = []

func _ready() -> void:
	layer = 2
	visible = force_visible or DisplayServer.is_touchscreen_available()
	if not visible:
		return
	_surface = Node2D.new()
	add_child(_surface)
	for entry in [["move_left", "←"], ["move_right", "→"],
		["move_up", "↑"], ["move_down", "↓"], ["jump", "JUMP"],
		["dash", "DASH"], ["attack", "SWORD"], ["toggle_help", "GUIDE"],
		["return_to_camp", "CAMP"]]:
		_add_button(entry[0], entry[1])
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var positions: Array[Vector2] = [Vector2(72, -220), Vector2(220, -220),
		Vector2(146, -294), Vector2(146, -146), Vector2(size.x - 80, -294),
		Vector2(size.x - 80, -146), Vector2(size.x - 190, -220),
		Vector2(size.x - 80, -405), Vector2(80, -405)]
	for index in _buttons.size():
		_buttons[index].position = positions[index] + Vector2(0, size.y)

func _add_button(action: String, caption: String) -> void:
	var button := TouchScreenButton.new()
	button.action = action
	button.passby_press = true
	var shape := CircleShape2D.new()
	shape.radius = 35.0
	button.shape = shape
	_surface.add_child(button)
	_buttons.append(button)
	var disc := Polygon2D.new()
	var points := PackedVector2Array()
	for index in 32:
		points.append(Vector2.from_angle(TAU * index / 32.0) * 35.0)
	disc.polygon = points
	disc.color = Color("164b43cc")
	button.add_child(disc)
	button.pressed.connect(func() -> void: disc.color = Color("f2c45ce6"))
	button.released.connect(func() -> void: disc.color = Color("164b43cc"))
	var label := Label.new()
	label.text = caption
	label.position = Vector2(-35, -14)
	label.size = Vector2(70, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 14)
	button.add_child(label)
