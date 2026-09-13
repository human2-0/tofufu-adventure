class_name MenuBackdrop
extends Control
## Original vector scenery, drawn in viewport coordinates; no gameplay state.

var _time: float = 0.0
var _fufu: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/characters/fufu/soybean_fufu-idle-eight.png")
	atlas.region = Rect2(0, 0, atlas.atlas.get_width() / 4.0, atlas.atlas.get_height() / 2.0)
	_fufu = TextureRect.new()
	_fufu.texture = atlas
	_fufu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fufu.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fufu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fufu)

func _process(delta: float) -> void:
	_time += delta
	_fufu.position = size * Vector2(0.68, 0.30) + Vector2(0, sin(_time * 1.8) * 4)
	_fufu.size = Vector2(size.y * 0.43, size.y * 0.43)
	queue_redraw()

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color("e5efd9"))
	draw_circle(s * Vector2(0.81, 0.29), s.y * 0.22, Color("f9efc6"))
	_hill(0.67, Color("bfd7b5"), 36.0, 0.0)
	_hill(0.79, Color("a7c5a2"), 45.0, 1.5)
	_hill(0.92, Color("88ad91"), 34.0, 3.0)
	var path := PackedVector2Array([s * Vector2(0.78, 0.65), s * Vector2(0.82, 0.65), s * Vector2(0.96, 1), s * Vector2(0.66, 1)])
	draw_colored_polygon(path, Color("e8d9b0"))
	for i in 23:
		var p := Vector2(fmod(i * 137.0 + 79, s.x), s.y * (0.80 + fmod(i * 0.037, 0.19)))
		var sway := sin(_time + i) * 3.0
		draw_line(p, p + Vector2(sway, -22), Color("658b71"), 2, true)
		_leaf(p + Vector2(sway - 7, -15), Vector2(10, 5), Color("c8dfb1"))
		_leaf(p + Vector2(sway + 6, -22), Vector2(9, 5), Color("dfe8b7"))
	for i in 9:
		var p := s * Vector2(0.53 + fmod(i * 0.11, 0.45), 0.12 + fmod(i * 0.17, 0.55))
		p.y += sin(_time * 0.7 + i) * 12
		draw_circle(p, 3, Color("fff9df", 0.6 + sin(_time + i) * 0.25))

func _leaf(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	draw_colored_polygon(points, color)

func _hill(height: float, color: Color, amplitude: float, phase: float) -> void:
	var points := PackedVector2Array([Vector2(0, size.y)])
	for i in 33:
		var x := size.x * i / 32.0
		points.append(Vector2(x, size.y * height + sin(i / 8.0 + phase) * amplitude))
	points.append(size)
	draw_colored_polygon(points, color)
