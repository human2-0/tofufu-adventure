class_name ArmoredSnailVisuals
extends Node3D
## A small all-mesh snail body with a shell that reacts to knife deflection.

const CREAM := Color("e9dcae")
const BODY := Color("a7c883")
const BODY_LIGHT := Color("c3d99b")
const SHELL := Color("806249")
const SHELL_RIDGE := Color("b28a5c")
const SHELL_DARK := Color("594638")
const EYE := Color("fff3d2")
const PUPIL := Color("3b3a39")

var _body: Node3D
var _head: Node3D
var _shell: Node3D
var _flash_left: float = 0.0
var _dodge_left: float = 0.0
var _clock: float = 0.0
var _materials: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []
var _facing := Vector2(0, 1)

func _ready() -> void:
	_build_model()

func present(motion: Vector3, aim: Vector3, windup: float, shell_open: float, delta: float) -> void:
	_clock += delta
	_flash_left = maxf(0.0, _flash_left - delta)
	_dodge_left = maxf(0.0, _dodge_left - delta)
	var moving := Vector2(motion.x, motion.z).length_squared() > 0.04
	var direction := Vector2(aim.x, aim.z) if windup > 0.0 else Vector2(motion.x, motion.z)
	if direction.length_squared() > 0.01:
		_facing = direction.normalized()
	rotation.y = atan2(_facing.x, _facing.y)
	var bob := sin(_clock * 9.0) * 0.035 if moving else sin(_clock * 1.6) * 0.012
	_body.position.y = bob
	_body.rotation.z = sin(_clock * 9.0) * 0.035 if moving else 0.0
	var retract := clampf(windup / 0.65, 0.0, 1.0)
	_head.position.z = lerpf(0.45, 0.30, retract)
	_head.scale = Vector3.ONE * lerpf(1.0, 0.9, retract)
	var opening := clampf(shell_open / 0.65, 0.0, 1.0)
	_shell.position.y = lerpf(0.72, 0.88, opening)
	_shell.position.z = lerpf(-0.1, -0.20, opening)
	_shell.rotation.x = lerpf(0.0, -0.24, opening)
	var dodge := 1.0 + 0.13 * sin((1.0 - _dodge_left / 0.22) * PI) if _dodge_left > 0.0 else 1.0
	_shell.scale = Vector3(1.0, 0.82, 1.0) * dodge
	_apply_flash()

func dodge() -> void:
	_dodge_left = 0.22

func flash() -> void:
	_flash_left = 0.12

func _build_model() -> void:
	_body = Node3D.new()
	add_child(_body)
	_sphere(_body, "Foot", Vector3(0, 0.19, 0.03), Vector3(0.68, 0.22, 0.5), BODY)
	_sphere(_body, "Mantle", Vector3(0, 0.37, -0.07), Vector3(0.49, 0.38, 0.48), BODY_LIGHT)
	_shell = Node3D.new()
	_shell.position = Vector3(0, 0.72, -0.1)
	_body.add_child(_shell)
	_sphere(_shell, "Dome", Vector3.ZERO, Vector3(0.62, 0.53, 0.62), SHELL)
	_torus(_shell, "Lower lip", Vector3(0, -0.18, 0), 0.48, 0.56, SHELL_DARK)
	_torus(_shell, "Shell band", Vector3(0, 0.18, 0), 0.35, 0.39, SHELL_RIDGE)
	_torus(_shell, "Shell whorl", Vector3(0, 0.49, 0), 0.13, 0.18, SHELL_RIDGE)
	_sphere(_shell, "Whorl center", Vector3(0, 0.51, 0), Vector3(0.09, 0.045, 0.09), SHELL_DARK)
	_head = Node3D.new()
	_head.position = Vector3(0, 0, 0.45)
	_body.add_child(_head)
	_sphere(_head, "Head", Vector3(0, 0.45, 0), Vector3(0.32, 0.34, 0.34), BODY_LIGHT)
	_sphere(_head, "Snout", Vector3(0, 0.35, 0.23), Vector3(0.2, 0.13, 0.16), BODY)
	for side in [-1.0, 1.0]:
		_cylinder(_head, "Eye stalk", Vector3(side * 0.17, 0.72, 0.02), 0.045, 0.31, BODY)
		_sphere(_head, "Eye", Vector3(side * 0.17, 0.9, 0.04), Vector3.ONE * 0.135, EYE)
		_sphere(_head, "Pupil", Vector3(side * 0.17, 0.9, 0.14), Vector3.ONE * 0.055, PUPIL)

func _sphere(parent: Node3D, node_name: String, at: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	mesh.material = _material(tint)
	instance.mesh = mesh
	instance.scale = size * 2.0
	instance.position = at
	parent.add_child(instance)
	return instance

func _cylinder(parent: Node3D, node_name: String, at: Vector3, radius: float, height: float, tint: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.material = _material(tint)
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	return instance

func _torus(parent: Node3D, node_name: String, at: Vector3, inner: float, outer: float, tint: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 16
	mesh.ring_segments = 6
	mesh.material = _material(tint)
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
	return instance

func _material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 1.0
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_materials.append(material)
	_base_colors.append(tint)
	return material

func _apply_flash() -> void:
	var amount := clampf(_flash_left / 0.12, 0.0, 1.0)
	for index in _materials.size():
		_materials[index].albedo_color = _base_colors[index].lerp(CREAM, amount)
