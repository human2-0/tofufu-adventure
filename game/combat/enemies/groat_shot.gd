class_name GroatShot
extends BeeSting
## Reusable golden tofu groat with the authority's swept collision contract.

func _ready() -> void:
	launch_speed = 32.0
	top_level = true
	for i in 3:
		var grain := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.09
		mesh.height = 0.15
		mesh.radial_segments = 8
		mesh.rings = 4
		grain.mesh = mesh
		grain.position = Vector3((i - 1) * 0.10, 0, i * 0.08)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("f5d17b")
		material.emission_enabled = true
		material.emission = Color("d8a846")
		material.emission_energy_multiplier = 0.5
		grain.material_override = material
		add_child(grain)
	visible = false
