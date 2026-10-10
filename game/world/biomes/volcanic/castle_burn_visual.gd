class_name CastleBurnVisual
extends Node3D
## Eight reused ember flecks cling to the affected actor in world space.

var active: bool = false
var flecks: Array[MeshInstance3D] = []
var elapsed: float = 0.0

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffaf3c")
	material.emission_enabled = true
	material.emission = Color("ff7928")
	material.emission_energy_multiplier = 1.7
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shape := SphereMesh.new()
	shape.radius = 0.06
	shape.height = 0.16
	shape.radial_segments = 6
	shape.rings = 3
	for i in 8:
		var fleck := MeshInstance3D.new()
		fleck.mesh = shape
		fleck.material_override = material
		add_child(fleck)
		flecks.append(fleck)
	visible = false

func _process(delta: float) -> void:
	visible = active
	if not active: return
	elapsed += delta
	for i in 8:
		var angle := i * TAU / 8 + elapsed * 1.2
		flecks[i].position = Vector3(cos(angle) * 0.45, fmod(elapsed * 1.1 + i * 0.17, 1.4), sin(angle) * 0.45)
