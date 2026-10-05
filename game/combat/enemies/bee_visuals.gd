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
	for index in 5:
		_sphere(_body, Vector3(0, 0, -0.3 + index * 0.12), Vector3(0.34, 0.29, 0.12), Color("ffc544") if index % 2 == 0 else Color("493521"))
	_sphere(_body, Vector3(0, 0.03, 0.4), Vector3(0.28, 0.26, 0.25), Color("e7ac34"))
	for side in [-1.0, 1.0]:
		_sphere(_body, Vector3(side * 0.16, 0.12, 0.6), Vector3(0.07, 0.10, 0.04), Color("302b29"))
		var wing := Node3D.new()
		wing.position = Vector3(side * 0.21, 0.16, 0)
		_body.add_child(wing)
		_sphere(wing, Vector3(side * 0.28, 0, -0.05), Vector3(0.4, 0.035, 0.2), Color(0.88, 0.96, 1.0, 0.7))
		_wings.append(wing)
		var antenna := _sphere(_body, Vector3(side * 0.13, 0.32, 0.45), Vector3(0.025, 0.16, 0.025), Color("493521"))
		antenna.rotation.x = 0.45

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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	if color.a < 1.0: material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	view.material_override = material
	_materials.append(material)
	parent.add_child(view)
	return view
