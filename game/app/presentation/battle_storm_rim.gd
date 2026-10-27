class_name BattleStormRim
extends RefCounted
## Double-buffered terrain samples keep the decorative rim's expensive work bounded.
const SEGMENTS: int = 192
const PROFILES_PER_STEP: int = 16
var ground_point: Callable
var material: Material
var mesh := ImmediateMesh.new()
var center := Vector2.ZERO
var radius: float = 1.0
var _center := Vector2.ZERO
var _radius: float = 1.0
var _next: int = -1
var _profiles: Array[Array] = []

func request(at: Vector2, size: float) -> bool:
	if _next >= 0: return false
	if mesh.get_surface_count() > 0 and at == center and size == radius: return false
	_center = at
	_radius = size
	_next = 0
	_profiles.clear()
	return true

func step() -> void:
	if _next < 0: return
	var end := mini(SEGMENTS + 1, _next + PROFILES_PER_STEP)
	while _next < end:
		_profiles.append(_profile(Vector2.from_angle(_next * TAU / SEGMENTS)))
		_next += 1
	if _next <= SEGMENTS: return
	# The old complete mesh stays visible until every new profile is available.
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for i in SEGMENTS:
		_quad(_profiles[i], _profiles[i + 1], 0, Color("b9fff1ee"))
		_quad(_profiles[i], _profiles[i + 1], 1, Color("a95aef85"))
	mesh.surface_end()
	center = _center
	radius = _radius
	_next = -1
	_profiles.clear()

func _profile(direction: Vector2) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for distance: float in [maxf(0, _radius - 0.65), _radius, _radius + 3]:
		var at := direction * distance
		var ground: Vector3 = ground_point.call(_center.x + at.x, _center.y + at.y, 0.14)
		points.append(Vector3(at.x, ground.y, at.y))
	return points

func _quad(a: Array, b: Array, inner: int, tint: Color) -> void:
	for point: Vector3 in [a[inner], b[inner], b[inner + 1], a[inner], b[inner + 1], a[inner + 1]]:
		mesh.surface_set_color(tint)
		mesh.surface_add_vertex(point)
