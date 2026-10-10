class_name CelestialSoyRay
extends Node3D
## One bounded luminous soy bolt follows the existing swept projectile trajectory.

func _ready() -> void:
	top_level = true
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("bdefff")
	material.emission_enabled = true
	material.emission = Color("5dc8ff")
	material.emission_energy_multiplier = 0.8
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.022
	mesh.bottom_radius = 0.035
	mesh.height = 0.48
	mesh.radial_segments = 8
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.material_override = material
	view.rotation.x = PI / 2
	view.position.z = 0.22
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(view)

func present(at: Vector3, velocity: Vector3) -> void:
	global_position = at
	if not velocity.is_zero_approx(): global_basis = Basis.looking_at(velocity, Vector3.RIGHT if absf(velocity.normalized().y) > 0.95 else Vector3.UP)
