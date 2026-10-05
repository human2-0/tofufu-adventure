class_name SotjetStreamVisual
extends MeshInstance3D
## Camera-facing milk ribbons and short impact droplets; no collision decisions.

var parcels: Array[SotjetParcel] = []
var radius: float = 0.055
var nozzle_provider: Callable
var nozzle := Vector3.ZERO
var pouring: bool = false
var _drawing: bool = false
var _surface := ImmediateMesh.new()
var _splashes: Array[Dictionary] = []

func _ready() -> void:
	mesh = _surface
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var milk := StandardMaterial3D.new()
	milk.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	milk.albedo_color = Color("fff5d6")
	milk.vertex_color_use_as_albedo = true
	milk.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = milk

func splash(at: Vector3, normal: Vector3) -> void:
	if _splashes.size() >= 12: _splashes.pop_front()
	_splashes.append({"at": at, "normal": normal, "age": 0.0})

func _process(delta: float) -> void:
	if nozzle_provider.is_valid(): nozzle = nozzle_provider.call()
	_surface.clear_surfaces()
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	_drawing = false
	for index in parcels.size():
		var parcel := parcels[index]
		var correction := parcel.visual_offset * maxf(0.0, 1.0 - parcel.age / 0.15) if parcel.reflections == 0 else Vector3.ZERO
		var end := parcel.previous + correction
		if index + 1 < parcels.size():
			var next := parcels[index + 1]
			if next.sequence == parcel.sequence + 1 and next.burst == parcel.burst and next.reflections == parcel.reflections and next.reflected_by == parcel.reflected_by: end = _position(next)
		elif pouring and parcel.age < 0.06 and parcel.reflections == 0:
			end = nozzle
		_ribbon(_position(parcel), end, radius, camera)
	for splash_data in _splashes:
		splash_data.age += delta
		var age: float = splash_data.age
		for index in 4:
			var spread := Vector3(cos(index * TAU / 4), 0.8, sin(index * TAU / 4))
			var at: Vector3 = splash_data.at + (spread + splash_data.normal) * age * 1.2 + Vector3.DOWN * age * age * 3.0
			_drop(at, 0.055 * (1.0 - age / 0.35), camera)
	if _drawing: _surface.surface_end()
	for index in range(_splashes.size() - 1, -1, -1):
		if _splashes[index].age >= 0.35: _splashes.remove_at(index)

func _ribbon(a: Vector3, b: Vector3, width: float, camera: Camera3D) -> void:
	if a.distance_squared_to(b) < 0.000001 or width <= 0: return
	if not _drawing:
		_surface.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_drawing = true
	var side := (b - a).cross(camera.global_position - (a + b) * 0.5).normalized() * width
	_surface.surface_set_color(Color.WHITE)
	for point in [a - side, a + side, b + side, a - side, b + side, b - side]:
		_surface.surface_add_vertex(point)
	_drop(a, width, camera)
	_drop(b, width, camera)

func _drop(at: Vector3, size: float, camera: Camera3D) -> void:
	if size <= 0.0: return
	if not _drawing:
		_surface.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_drawing = true
	var right := camera.global_basis.x * size
	var up := camera.global_basis.y * size
	for index in 16:
		var a := index * TAU / 16.0
		var b := (index + 1) * TAU / 16.0
		_surface.surface_set_color(Color.WHITE)
		_surface.surface_add_vertex(at)
		_surface.surface_set_color(Color(0.93, 0.93, 0.87))
		_surface.surface_add_vertex(at + right * cos(a) + up * sin(a))
		_surface.surface_add_vertex(at + right * cos(b) + up * sin(b))

func _position(parcel: SotjetParcel) -> Vector3:
	if parcel.reflections > 0: return parcel.position
	return parcel.position + parcel.visual_offset * maxf(0.0, 1.0 - parcel.age / 0.15)
