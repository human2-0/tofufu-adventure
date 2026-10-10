class_name CelestialWeaponModel
extends Node3D
## Authored 3D silhouettes match the generated armory icons in every camera angle.

@export_enum("Laurel Sword", "Olympian Staff", "Soy Raygun") var kind: int = 0
const GEOMETRY := preload("res://game/combat/celestial_weapon_geometry.gd")
var pearl: StandardMaterial3D
var gold: StandardMaterial3D
var light: StandardMaterial3D

func _ready() -> void:
	pearl = _material(Color("f5f0e3"), 0.12)
	gold = _material(Color("e6bb5a"), 0.65)
	light = _material(Color("9ddfff"), 0.15)
	light.emission_enabled = true
	light.emission = Color("5faade")
	light.emission_energy_multiplier = 0.65
	if kind == 0: _sword()
	elif kind == 1: _staff()
	else: _raygun()

func _sword() -> void:
	_box(Vector3(0, -0.23, 0), Vector3(0.1, 0.46, 0.1), pearl)
	for y in [-0.41, -0.28, -0.15, -0.02]: _ring(Vector3(0, y, 0), 0.075, gold)
	_box(Vector3.ZERO, Vector3(0.36, 0.065, 0.12), gold)
	_star(Vector3(0, 0.025, 0.068), 0.05)
	_blade(1.0, 0.12, pearl)
	_box(Vector3(0, 0.43, 0.038), Vector3(0.018, 0.7, 0.012), light)
	_star(Vector3(0, -0.49, 0), 0.07)
	_wings(Vector3.ZERO, 0.12)

func _staff() -> void:
	_cylinder(Vector3(0, -0.04, 0), 0.045, 1.72, pearl)
	for y in [-0.8, -0.6, -0.45, 0.12, 0.58, 0.75]: _ring(Vector3(0, y, 0), 0.065, gold)
	_wings(Vector3(0, 0.74, 0), 0.18)
	var crown := _ring(Vector3(0, 0.93, 0), 0.19, gold)
	crown.rotation.x = PI / 2
	_star(Vector3(0, 0.94, 0), 0.14)
	_star(Vector3(0, -0.91, 0), 0.065)

func _raygun() -> void:
	# The gun's grip is the origin; its barrel extends along local -Z.
	_box(Vector3(0, -0.12, 0.06), Vector3(0.13, 0.25, 0.12), pearl)
	for y in [-0.18, -0.08]: _box(Vector3(0, y, 0.065), Vector3(0.15, 0.026, 0.13), gold)
	_box(Vector3(0, 0.1, -0.16), Vector3(0.23, 0.22, 0.38), pearl)
	for y in [0.005, 0.195]: _box(Vector3(0, y, -0.16), Vector3(0.25, 0.028, 0.37), gold)
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 0.119, 0.1, -0.09), Vector3(0.016, 0.13, 0.14), gold)
	var rear := _ring(Vector3(0, 0.1, 0.04), 0.085, gold)
	rear.rotation.x = PI / 2
	_star(Vector3(0, 0.1, 0.054), 0.065)
	var barrel := _cylinder(Vector3(0, 0.1, -0.39), 0.105, 0.26, pearl)
	barrel.rotation.x = PI / 2
	for z in [-0.32, -0.44, -0.53]:
		var rim := _ring(Vector3(0, 0.1, z), 0.12, gold)
		rim.rotation.x = PI / 2
	var lens := _cylinder(Vector3(0, 0.1, -0.54), 0.085, 0.02, light)
	lens.rotation.x = PI / 2
	var core := _ring(Vector3(0, 0.1, -0.1), 0.075, gold)
	core.rotation.z = PI / 2
	_star(Vector3(0.126, 0.1, -0.1), 0.055)
	_star(Vector3(-0.126, 0.1, -0.1), 0.055)
	_wings(Vector3(0, 0.13, 0.005), 0.075)
	_box(Vector3(0, 0.25, -0.19), Vector3(0.035, 0.08, 0.05), gold)

func _blade(length: float, width: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		var vertices: Array[Vector3] = [Vector3(-width, 0.06, 0), Vector3(0, length, 0), Vector3(width, 0.06, 0), Vector3(0, 0.06, side * 0.035)]
		for tri in [[0, 1, 3], [1, 2, 3]]:
			if side < 0: tri.reverse()
			for index in tri: surface.add_vertex(vertices[index])
	surface.generate_normals()
	_view(surface.commit(), Vector3.ZERO, material)

func _wings(at: Vector3, span: float) -> void:
	for side in [-1.0, 1.0]:
		for feather in 3:
			var view := _view(GEOMETRY.feather(span * 1.05, span * 0.4), at + Vector3(side * (span + feather * span * 0.22), 0.04 + feather * span * 0.26, 0), pearl)
			view.rotation.z = side * (-0.35 - feather * 0.2)

func _star(at: Vector3, radius: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.8
	mesh.radial_segments = 4
	mesh.rings = 2
	_view(mesh, at, light)

func _ring(at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.015
	mesh.outer_radius = radius + 0.015
	mesh.rings = 16
	mesh.ring_segments = 8
	return _view(mesh, at, material)

func _cylinder(at: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	return _view(mesh, at, material)

func _box(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	return _view(GEOMETRY.panel(size), at, material)

func _view(mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = material
	view.position = at
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)
	return view

func _material(color: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = 0.45
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return material
