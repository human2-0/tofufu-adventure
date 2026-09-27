class_name MapCanvas
extends Control
## North-up map with a local crop, zoomable overview and a separate fogged terrain layer.

var terrain_texture: Texture2D
var fog_texture: Texture2D
var bounds := Rect2(-42, -42, 84, 84)
var markers: Array[Dictionary] = []
var expanded: bool = false
var center := Vector2.ZERO
var heading := Vector2.DOWN
var zoom: float = 1.0
var _background := TextureRect.new()
var _fog := ShaderMaterial.new()
var _dragging: bool = false

func _ready() -> void:
	clip_contents = true
	_fog.shader = preload("res://game/ui/map_fog.gdshader")
	_background.material = _fog
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background.show_behind_parent = true
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(_background)

func visible_bounds() -> Rect2:
	if not expanded: return Rect2(center - Vector2.ONE * 22 / zoom, Vector2.ONE * 44 / zoom)
	var aspect := maxf(size.x, 1) / maxf(size.y, 1)
	var extent := bounds.size
	if extent.x / extent.y < aspect: extent.x = extent.y * aspect
	else: extent.y = extent.x / aspect
	extent /= zoom
	return Rect2(center - extent * 0.5, extent)

func map_rect() -> Rect2:
	var extent := visible_bounds().size
	var scale_factor := minf(size.x / extent.x, size.y / extent.y)
	extent *= scale_factor
	return Rect2((size - extent) * 0.5, extent)

func project_point(point: Vector2) -> Vector2:
	var rect := map_rect()
	var area := visible_bounds()
	return rect.position + (point - area.position) / area.size * rect.size

func unproject_point(point: Vector2) -> Vector2:
	var rect := map_rect()
	return visible_bounds().position + (point - rect.position) / rect.size * visible_bounds().size

func reset_overview() -> void:
	zoom = 1.0
	center = bounds.get_center()
	queue_redraw()

func _draw() -> void:
	var rect := map_rect()
	var area := visible_bounds()
	_background.position = rect.position
	_background.size = rect.size
	_background.texture = terrain_texture
	_fog.set_shader_parameter("explored", fog_texture)
	_fog.set_shader_parameter("view_origin", (area.position - bounds.position) / bounds.size)
	_fog.set_shader_parameter("view_scale", area.size / bounds.size)
	draw_rect(rect, Color("f4c75d"), false, 2)
	for marker in markers:
		if not area.has_point(marker.point): continue
		var point := project_point(marker.point)
		if not rect.grow(-9).has_point(point): continue
		if marker.get("local", false):
			_draw_heading(point)
		else:
			var radius := 5.0 if expanded else 4.0
			draw_circle(point, radius + 2, Color("20332e"))
			if marker.kind == "npc": draw_rect(Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2), marker.color)
			else: draw_circle(point, radius, marker.color)
		if expanded and (zoom >= 3 or marker.get("local", false)): _draw_caption(marker, point, rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, 18), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff7dc"))
	if not expanded:
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 8, rect.end.y - 8), "%dm" % roundi(44 / zoom), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fff7dc"))

func _draw_heading(point: Vector2) -> void:
	var forward := heading.normalized()
	var right := Vector2(-forward.y, forward.x)
	var cone := PackedVector2Array([point, point + forward.rotated(-0.5) * 30, point + forward.rotated(0.5) * 30])
	draw_colored_polygon(cone, Color(0.55, 0.88, 1, 0.24))
	var arrow := PackedVector2Array([point + forward * 11, point - forward * 7 + right * 7, point - forward * 3, point - forward * 7 - right * 7])
	draw_colored_polygon(arrow, Color("fff7dc"))
	arrow.append(arrow[0])
	draw_polyline(arrow, Color("183f48"), 2, true)

func _draw_caption(marker: Dictionary, point: Vector2, rect: Rect2) -> void:
	var font := ThemeDB.fallback_font
	var caption: String = str(marker.label).left(24)
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var at := point + Vector2(10, -9)
	if at.x + width > rect.end.x - 4: at.x = point.x - width - 10
	at.x = maxf(rect.position.x + 4, at.x)
	at.y = clampf(at.y, rect.position.y + 18, rect.end.y - 6)
	draw_string_outline(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("233d36"))
	draw_string(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff4d9"))

func _gui_input(event: InputEvent) -> void:
	if not expanded: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position, 1.3 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.3)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		center -= event.relative / map_rect().size * visible_bounds().size
		_clamp_center()
		queue_redraw()
		accept_event()

func zoom_at(point: Vector2, factor: float) -> void:
	var before := unproject_point(point)
	zoom = clampf(zoom * factor, 1, 16)
	center += before - unproject_point(point)
	_clamp_center()
	queue_redraw()

func _clamp_center() -> void:
	var half := visible_bounds().size * 0.5
	var travel := (bounds.size * 0.5 - half).max(Vector2.ZERO)
	center = center.clamp(bounds.get_center() - travel, bounds.get_center() + travel)

func _get_tooltip(at: Vector2) -> String:
	for marker in markers:
		if project_point(marker.point).distance_to(at) < 12: return str(marker.label)
	return ""
