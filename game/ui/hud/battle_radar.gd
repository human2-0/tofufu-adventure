class_name BattleRadar
extends Control
## Map values only: allies, safe zone and fading, stationary gunfire markers.

var position_on_map := Vector2.ZERO
var center := Vector2.ZERO
var next_center := Vector2.ZERO
var next_radius: float = 240
var destination := Vector2.ZERO
var radius: float = 420
var expanded: bool = false
var heading := Vector2.UP
var _terrain: TextureRect
var _shader: ShaderMaterial
var map_bounds := Rect2(-500, -500, 1000, 1000)
var terrain_map: Texture2D
var chests: Array = []
var teammates: Array[Vector2] = []
var gunfire: Array[Vector3] = [] # Map X/Z and opacity; no live enemy positions.
var squad_pings: Array[Vector3] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(100, 100)
	_shader = ShaderMaterial.new()
	_shader.shader = preload("res://game/ui/hud/battle_radar.gdshader")
	_terrain = TextureRect.new()
	_terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_terrain.show_behind_parent = true
	_terrain.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_terrain.material = _shader
	add_child(_terrain)

func _draw() -> void:
	var span := map_bounds.size.x if expanded else clampf(radius * 2.4, 240, 600)
	var view_center := map_bounds.get_center() if expanded else position_on_map
	var scale_factor := (minf(size.x, size.y) - 16) / span
	var origin := size * 0.5 - view_center * scale_factor
	var panel := MenuStyle.panel(Color.TRANSPARENT, 12)
	panel.border_color = Color("a9cfac65")
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	_terrain.texture = terrain_map
	_terrain.position = Vector2(8, 8)
	_terrain.size = size - Vector2(16, 16)
	_shader.set_shader_parameter("safe_center", (center - map_bounds.position) / map_bounds.size)
	_shader.set_shader_parameter("safe_radius", radius / map_bounds.size.x)
	_shader.set_shader_parameter("map_center", (view_center - map_bounds.position) / map_bounds.size)
	_shader.set_shader_parameter("map_span", span / map_bounds.size.x)
	for x in range(-400, 901, 100):
		draw_line(origin + Vector2(x, -500) * scale_factor, origin + Vector2(x, 900) * scale_factor, Color("4e7262"))
	for z in range(-400, 901, 100):
		draw_line(origin + Vector2(-500, z) * scale_factor, origin + Vector2(900, z) * scale_factor, Color("4e7262"))
	draw_circle(origin + center * scale_factor, radius * scale_factor, Color("c9efbb"), false, 2, true)
	for i in range(0, 64, 2):
		var a := Vector2.from_angle(i * TAU / 64) * next_radius
		var b := Vector2.from_angle((i + 1) * TAU / 64) * next_radius
		draw_line(origin + (next_center + a) * scale_factor, origin + (next_center + b) * scale_factor, Color("fff9e9b0"), 1.5, true)
	for chest: Vector2 in chests:
		draw_rect(Rect2(origin + chest * scale_factor - Vector2.ONE * 1.5, Vector2.ONE * 3), Color("f4c75d"))
	for teammate in teammates: draw_circle(origin + teammate * scale_factor, 4, Color("78e5ef"))
	for ping in squad_pings:
		var at := origin + Vector2(ping.x, ping.y) * scale_factor
		var color := Color("ff6c71") if ping.z > 0 else Color("78e5ef")
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -6), at + Vector2(6, 0), at + Vector2(0, 6), at + Vector2(-6, 0)]), color)
	for ping in gunfire:
		var at := origin + Vector2(ping.x, ping.y) * scale_factor
		draw_circle(at, 6, Color(0.12, 0.02, 0.02, ping.z * 0.8), false, 2, true)
		draw_circle(at, 3.5, Color(1, 0.18, 0.2, ping.z), true, -1, true)
	var marker := position_on_map.clamp(map_bounds.position + Vector2.ONE * 10, map_bounds.end - Vector2.ONE * 10)
	var at := origin + marker * scale_factor
	var direction := heading.normalized()
	var side := direction.orthogonal()
	draw_circle(at, 7, Color("102d28dd"))
	draw_colored_polygon(PackedVector2Array([at + direction * 7, at - direction * 5 + side * 5, at - direction * 3, at - direction * 5 - side * 5]), Color("ffe19b"))
	draw_line(origin + marker * scale_factor, origin + destination * scale_factor, Color("f4c75d88"), 1, true)
	if expanded:
		draw_rect(Rect2(Vector2(8, 8), Vector2(size.x - 16, 42)), Color("153a35ee"))
		draw_circle(Vector2(17, 21), 3.5, Color("ff2e33"))
		draw_string(ThemeDB.fallback_font, Vector2(26, 26), tr("Gunfire · 100 m · 2 s"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, 13, Color("fff3dc"))
		draw_string(ThemeDB.fallback_font, Vector2(14, 43), tr("Dashed ring: next zone"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 12, Color("fff3dc"))
