class_name CelestialAura
extends Node3D
## Three soft rings and eight motes; no lights, gameplay state or particle spawning.

var _rings: Array[MeshInstance3D] = []
var _motes: Array[MeshInstance3D] = []
var _time: float = 0.0
var _glow: StandardMaterial3D

func _ready() -> void:
	_glow = StandardMaterial3D.new()
	_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow.albedo_color = Color(1.0, 0.85, 0.5, 0.24)
	_glow.emission_enabled = true
	_glow.emission = Color("ffe0a0")
	for index in 3:
		var ring := TorusMesh.new()
		var radius := 0.31 if index == 0 else 0.62 + index * 0.06
		ring.inner_radius = radius - 0.008
		ring.outer_radius = radius + 0.008
		ring.rings = 32
		ring.ring_segments = 6
		var view := _mesh(ring)
		view.position.y = 0.95 if index == 0 else -0.50 + index * 0.008
		_rings.append(view)
	var spark := SphereMesh.new()
	spark.radius = 0.016
	spark.height = 0.06
	spark.radial_segments = 4
	spark.rings = 2
	for index in 8: _motes.append(_mesh(spark))
	set_active(false)

func _mesh(mesh: Mesh) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = _glow
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	return view

func set_active(active: bool) -> void:
	visible = active
	set_process(active)

func _process(delta: float) -> void:
	_time += delta
	_glow.albedo_color.a = 0.22 + sin(_time * 1.8) * 0.07
	_rings[0].position.y = 0.95 + sin(_time * 1.4) * 0.025
	for index in _motes.size():
		var angle := index * TAU / 8.0 + _time * 0.24
		var rise := fposmod(_time * 0.16 + float(index) / 8.0, 1.0)
		_motes[index].position = Vector3(cos(angle) * 0.57, -0.35 + rise * 1.2, sin(angle) * 0.57)
		_motes[index].scale = Vector3.ONE * sin(rise * PI)
