class_name BeeVisuals
extends Node3D
## Small striped bee with beating translucent wings and a readable attack pose.

var _wings: Array[Node3D] = []
var _body: Node3D
var _phase: float = 0.0
var _flash: float = 0.0
var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	_body = Node3D.new()
	_body.position.y = 0.72
	add_child(_body)
	var body := MeshInstance3D.new()
	body.name = "ShapedStripedBody"
	body.mesh = BeeMesh.body()
	body.material_override = _material(Color.WHITE)
	body.material_override.vertex_color_use_as_albedo = true
	_body.add_child(body)
	_stinger()
	for side in [-1.0, 1.0]:
		_sphere(_body, Vector3(side * 0.17, 0.12, 0.65), Vector3(0.075, 0.11, 0.04), Color("302b29"))
		_sphere(_body, Vector3(side * 0.185, 0.16, 0.68), Vector3.ONE * 0.023, Color("fff7d5"))
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.21, 0.16, 0)
		_body.add_child(wing)
		var view := MeshInstance3D.new()
		view.name = "VeinedForeAndHindWing"
		view.mesh = BeeMesh.wing()
		view.scale.x = side
		view.set_surface_override_material(0, _material(Color(0.88, 0.96, 1.0, 0.56), true))
		view.set_surface_override_material(1, _material(Color("93bab6"), true))
		view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		wing.add_child(view)
		_wings.append(wing)
		var antenna := _sphere(_body, Vector3(side * 0.13, 0.32, 0.45), Vector3(0.025, 0.16, 0.025), Color("493521"))
		antenna.rotation.x = 0.45
		_sphere(_body, Vector3(side * 0.13, 0.47, 0.39), Vector3.ONE * 0.043, Color("493521"))
		for index in 3:
			var leg := _sphere(_body, Vector3(side * 0.24, -0.22, 0.22 - index * 0.18), Vector3(0.026, 0.18, 0.026), Color("493521"))
			leg.rotation.z = side * 0.65
			_sphere(_body, Vector3(side * 0.35, -0.36, 0.24 - index * 0.18), Vector3(0.065, 0.025, 0.025), Color("493521"))

func present(facing: Vector3, windup: float, delta: float) -> void:
	_phase += delta
	_flash = maxf(0.0, _flash - delta)
	rotation.y = atan2(facing.x, facing.z)
	_body.position.y = 0.72 + sin(_phase * 8.0) * 0.06
	_body.rotation.x = -0.2 if windup > 0.0 else 0.0
	for index in _wings.size():
		_wings[index].rotation.z = sin(_phase * 55.0) * 0.65 * (-1.0 if index == 0 else 1.0)
	for material in _materials:
		material.emission_enabled = _flash > 0.0 or windup > 0.0
		material.emission = Color("ff7860") if _flash > 0.0 else Color("9e6c13")

func flash() -> void:
	_flash = 0.2

func _sphere(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = at
	view.scale = size
	view.material_override = _material(color)
	parent.add_child(view)
	return view

func _material(color: Color, two_sided: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	result.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	if two_sided: result.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1.0: result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials.append(result)
	return result

func _stinger() -> void:
	var view := MeshInstance3D.new()
	view.name = "Stinger"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.07
	mesh.height = 0.2
	mesh.radial_segments = 8
	view.mesh = mesh
	view.material_override = _material(Color("493521"))
	view.position = Vector3(0, 0, -0.68)
	view.rotation.x = -PI / 2
	_body.add_child(view)
