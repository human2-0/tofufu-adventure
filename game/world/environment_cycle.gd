class_name EnvironmentCycle
extends Node3D

signal time_changed(hour: float, daylight: float)
@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment
@export var cycle_seconds: float = 180.0
var phase: float = 0.35
var cloud_cover: float = 0.0
var _clouds: float = 0.0
var _motes: MultiMeshInstance3D
var _lights: Array[OmniLight3D] = []
var _time: float = 0.0
var sky_effects: SkyEffects

func _ready() -> void:
	# A local preview or co-op test may contain multiple independent worlds.
	world_environment.environment = world_environment.environment.duplicate(true)
	sky_effects = SkyEffects.new()
	add_child(sky_effects)
	sky_effects.setup(world_environment.environment)
	_build_motes()
	for at in [Vector3(-22, 4.5, -17), Vector3(19, 1.5, -4), Vector3(29, 2, 18), Vector3(7, 1.5, 4), Vector3(15, 1.5, 4)]: 
		var light := OmniLight3D.new()
		light.position = at
		light.light_color = Color("ffd18d")
		light.omni_range = 7.0
		add_child(light)
		_lights.append(light)
		MeadowGeometry.box(self, at, Vector3(0.25, 0.4, 0.25), Color("ffe3a2"))
		MeadowGeometry.box(self, at - Vector3.UP * 0.85, Vector3(0.12, 1.3, 0.12), Color("645746"))
		MeadowGeometry.box(self, at + Vector3.UP * 0.25, Vector3(0.4, 0.1, 0.4), Color("645746"))

func _process(delta: float) -> void:
	_time += delta
	_clouds = move_toward(_clouds, cloud_cover, delta * 0.25)
	phase = fposmod(phase + delta / cycle_seconds, 1.0)
	var daylight := clampf(sin(phase * TAU - PI * 0.5) * 1.5, 0.0, 1.0)
	sun.rotation_degrees = Vector3(-15.0 - daylight * 50.0, phase * 180.0 - 90.0, 0)
	sun.light_energy = lerpf(0.18, 0.7, daylight) * lerpf(1.0, 0.42, _clouds)
	sun.light_color = Color("94b4e8").lerp(Color("fff0df"), daylight)
	var environment := world_environment.environment
	environment.ambient_light_color = Color("7b90bd").lerp(Color("d6ebed"), daylight)
	environment.ambient_light_energy = lerpf(0.55, 0.7, daylight)
	environment.fog_enabled = true
	environment.fog_density = lerpf(0.0025, 0.012, _clouds)
	environment.fog_light_color = Color("394965").lerp(Color("d9e8da"), daylight)
	var flash := sky_effects.present(delta, phase, daylight, _clouds)
	sun.light_energy += flash * 0.45
	environment.fog_light_color = environment.fog_light_color.lerp(Color("7d939e"), _clouds * 0.6)
	for light in _lights:
		light.light_energy = (1.0 - daylight) * (1.5 + sin(_time * 3.0) * 0.1)
	_motes.visible = daylight < 0.7
	_animate_motes()
	time_changed.emit(phase * 24.0, daylight)

func _build_motes() -> void:
	_motes = MultiMeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.035
	mesh.height = 0.07
	mesh.radial_segments = 4
	mesh.rings = 3
	var material := MeadowGeometry.material(Color("e4ffc0"))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color("b5ef8a")
	mesh.material = material
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = 90
	_motes.multimesh = multi
	add_child(_motes)

func _animate_motes() -> void:
	for i in _motes.multimesh.instance_count:
		var at := Vector3(sin(i * 73.1) * 27, 1.0 + sin(_time + i) * 0.6, cos(i * 31.7) * 28)
		at.x += sin(_time * 0.5 + i) * 0.6
		_motes.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, at))
