class_name BattlePlantMap
extends Control
## Clickable deployment map. Availability and ownership arrive as display values.
signal selected(index: int)
var terrain: Texture2D
var sites: Array = []
var states: Array[int] = [] # 0 free, 1 enemy reservation, 2 local, 3 teammate.
var highlighted: int = -1

func _ready() -> void:
	custom_minimum_size = Vector2(160, 120)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_click)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _map_rect() -> Rect2:
	var edge := minf(size.x, size.y) - 8
	return Rect2((size - Vector2.ONE * edge) * 0.5, Vector2.ONE * edge)

func _point(index: int) -> Vector2:
	var rect := _map_rect()
	return rect.position + (Vector2(sites[index][0], sites[index][2]) + Vector2.ONE * 500) / 1000 * rect.size

func _draw() -> void:
	var rect := _map_rect()
	draw_style_box(MenuStyle.panel(Color("142e28"), 8), Rect2(Vector2.ZERO, size))
	if terrain != null: draw_texture_rect(terrain, rect, false)
	for index in sites.size():
		var color: Color = [Color("a0e4a5"), Color("647269"), Color("ffd578"), Color("78e5ef")][states[index]]
		var at := _point(index)
		draw_circle(at, 4 if states[index] in [2, 3] else 3, Color("10251c"))
		draw_circle(at, 3 if states[index] in [2, 3] else 2, color)
		if index == highlighted: draw_circle(at, 7, Color("fff1b5"), false, 2, true)

func _click(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	var nearest := -1
	var distance := 100.0
	for index in sites.size():
		var candidate := _point(index).distance_squared_to(event.position)
		if candidate < distance:
			nearest = index
			distance = candidate
	if nearest >= 0: selected.emit(nearest)
	accept_event()
