class_name MeadowHearth
extends Node3D
## Cast-iron wood range, recognizable cookware and bounded local boiling/fire VFX.

var _fire_light: OmniLight3D
var _time: float = 0.0

func _ready() -> void:
	name = "WoodFiredHob"
	position = Vector3(-1.4, 0, -2.5)
	_range()
	_kettle()
	_pan(Vector3(0.48, 1.77, 0.08), false)
	_pan(Vector3(1.2, 2.15, -0.72), true)
	_particles("KettleSteam", Vector3(-0.45, 2.34, 0.1), true)
	_particles("WoodFlames", Vector3(0, 0.78, 0.81), false)
	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(0, 0.94, 1.1)
	_fire_light.light_color = Color("ff943d")
	_fire_light.light_energy = 0.85
	_fire_light.omni_range = 3.5
	add_child(_fire_light)

func _process(delta: float) -> void:
	_time += delta
	_fire_light.light_energy = 0.85 + sin(_time * 8) * 0.10 + sin(_time * 13) * 0.04

func _range() -> void:
	MeadowGeometry.box(self, Vector3(0, 1.07, 0), Vector3(2.0, 1.14, 1.6), Color("454a45"), true)
	MeadowGeometry.box(self, Vector3(0, 1.67, 0), Vector3(2.12, 0.14, 1.74), Color("293335"))
	for x in [-0.47, 0.47]:
		_ring(self, Vector3(x, 1.75, 0.05), 0.32, Color("151e21"))
	MeadowGeometry.box(self, Vector3(0, 0.89, 0.815), Vector3(0.88, 0.52, 0.025), Color("251e1a"))
	for x in [-0.32, -0.16, 0, 0.16, 0.32]:
		MeadowGeometry.box(self, Vector3(x, 0.86, 0.86), Vector3(0.035, 0.4, 0.055), Color("363b3b"))
	for i in 3:
		MeadowGeometry.box(self, Vector3(-0.2 + i * 0.2, 0.71, 0.84), Vector3(0.11, 0.11, 0.09), Color("ea7c2c"))
	MeadowGeometry.box(self, Vector3(0.58, 1.03, 0.86), Vector3(0.24, 0.08, 0.10), Color("a6a18e"))
	MeadowGeometry.box(self, Vector3(0.68, 0.59, 0.1), Vector3(0.55, 0.12, 1.2), Color("717069"))
	_cylinder(self, Vector3(0, 2.31, -0.67), 0.14, 1.45, Color("454b48"))
	for x in [-0.8, 0.8]:
		for z in [-0.6, 0.6]:
			MeadowGeometry.box(self, Vector3(x, 0.37, z), Vector3(0.15, 0.3, 0.15), Color("323d3c"))

func _kettle() -> void:
	var kettle := Node3D.new()
	kettle.name = "BoilingKettle"
	kettle.position = Vector3(-0.45, 1.79, 0.08)
	add_child(kettle)
	MeadowGeometry.rock(kettle, Vector3(0, 0.20, 0), Vector3(0.32, 0.24, 0.32), Color("c4c8b7"))
	_cylinder(kettle, Vector3(0, 0.40, 0), 0.24, 0.05, Color("737f7e"))
	MeadowGeometry.rock(kettle, Vector3(0, 0.46, 0), Vector3(0.055, 0.05, 0.055), Color("364647"))
	var handle := _ring(kettle, Vector3(0, 0.43, 0), 0.29, Color("3a4240"))
	handle.rotation.x = PI / 2
	var spout := _cylinder(kettle, Vector3(0.29, 0.28, 0.05), 0.07, 0.32, Color("b4c0b6"))
	spout.rotation.z = -0.8
	_ring(kettle, Vector3(0.38, 0.40, 0.05), 0.065, Color("5e7071"))

func _pan(at: Vector3, hanging: bool) -> void:
	var pan := Node3D.new()
	pan.name = "HangingSkillet" if hanging else "IronFryingPan"
	pan.position = at
	add_child(pan)
	_cylinder(pan, Vector3.ZERO, 0.33, 0.055, Color("202b2c"))
	_ring(pan, Vector3(0, 0.04, 0), 0.32, Color("515b58"))
	MeadowGeometry.box(pan, Vector3(0, 0, 0.57), Vector3(0.11, 0.09, 0.63), Color("333d3b"))
	if hanging: pan.rotation.x = PI / 2

func _particles(title: String, at: Vector3, steam: bool) -> void:
	var puff := GPUParticles3D.new()
	puff.name = title
	puff.position = at
	puff.amount = 28 if steam else 18
	puff.lifetime = 1.8 if steam else 0.55
	puff.preprocess = puff.lifetime
	puff.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	var motion := ParticleProcessMaterial.new()
	motion.direction = Vector3.UP
	motion.spread = 12 if steam else 6
	motion.gravity = Vector3(0, 0.05, 0)
	motion.initial_velocity_min = 0.32 if steam else 0.7
	motion.initial_velocity_max = 0.65 if steam else 1.1
	motion.scale_min = 0.14 if steam else 0.08
	motion.scale_max = 0.30 if steam else 0.17
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)]) if steam else PackedColorArray([Color("ffe79a"), Color("f99936"), Color(0.9, 0.2, 0.04, 0)])
	fade.offsets = PackedFloat32Array([0, 0.22, 1])
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	motion.color_ramp = ramp
	puff.process_material = motion
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _soft_puff()
	material.no_depth_test = false
	material.disable_receive_shadows = true
	quad.material = material
	puff.draw_pass_1 = quad
	add_child(puff)

static func _soft_puff() -> GradientTexture2D:
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = fade
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	texture.width = 32
	texture.height = 32
	return texture

static func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	mesh.material = MeadowGeometry.material(color)
	return _mesh(parent, mesh, at)

static func _ring(parent: Node3D, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius * 0.86
	mesh.outer_radius = radius
	mesh.rings = 16
	mesh.ring_segments = 8
	mesh.material = MeadowGeometry.material(color)
	return _mesh(parent, mesh, at)

static func _mesh(parent: Node3D, mesh: Mesh, at: Vector3) -> MeshInstance3D:
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = at
	parent.add_child(view)
	return view
