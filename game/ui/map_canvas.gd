class_name MapCanvas
extends Control
## North-up X/Z atlas shared by the compact and expanded views.

var terrain_texture: Texture2D
var bounds := Rect2(-42, -42, 84, 84)
var markers: Array[Dictionary] = []
var expanded: bool = false

func map_rect() -> Rect2:
	var scale_factor := minf(size.x / bounds.size.x, size.y / bounds.size.y)
	var extent := bounds.size * scale_factor
	return Rect2((size - extent) * 0.5, extent)

func project_point(point: Vector2) -> Vector2:
	var rect := map_rect()
	return rect.position + (point - bounds.position) / bounds.size * rect.size

func _draw() -> void:
	var rect := map_rect()
	if terrain_texture != null: draw_texture_rect(terrain_texture, rect, false)
	draw_rect(rect, Color("d9d6ae"), false, 2)
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(8, 18), "N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("233d36"))
	for marker in markers:
		var point := project_point(marker.point)
		var color: Color = marker.color
		var radius := 6.0 if expanded else 4.0
		draw_circle(point, radius + 2, Color("20332e"))
		if marker.kind == "npc":
			draw_rect(Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2), color)
		else: draw_circle(point, radius, color)
		if expanded:
			var caption: String = str(marker.label).left(24)
			var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			var at := point + Vector2(10, -9)
			if at.x + width > rect.end.x - 4: at.x = point.x - width - 10
			at.y = clampf(at.y, rect.position.y + 18, rect.end.y - 6)
			draw_string_outline(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("233d36"))
			draw_string(font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("fff4d9"))
