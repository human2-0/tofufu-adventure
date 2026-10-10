class_name MeadowMachineryDetails
extends RefCounted
## Recognizable tractor controls, grilles, wheel hubs and tire treads.

static func build_tractor(parent: Node3D) -> void:
	for side in [-1.0, 1.0]:
		for z in [-0.8, 0.8]:
			var radius := 0.65 if z < 0 else 0.42
			var hub := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = radius * 0.48
			cylinder.bottom_radius = radius * 0.48
			cylinder.height = 0.035
			cylinder.radial_segments = 16
			cylinder.material = MeadowGeometry.material(Color("af5640"))
			hub.mesh = cylinder
			hub.position = Vector3(side * 1.13, 0.6, z)
			hub.rotation.z = PI / 2
			parent.add_child(hub)
			for segment in 14:
				var angle := segment * TAU / 14
				var at := Vector3(side * 0.85, 0.6 + cos(angle) * radius, z + sin(angle) * radius)
				var tread := MeadowGeometry.box(parent, at, Vector3(0.5, 0.05, 0.10), Color("343c3d"))
				tread.rotation.x = angle
				tread.rotation.y = side * 0.25
		MeadowGeometry.box(parent, Vector3(side * 0.7, 1.19, -0.8), Vector3(0.5, 0.10, 1.4), Color("658948"))
		MeadowGeometry.box(parent, Vector3(side * 0.69, 0.72, 0.12), Vector3(0.25, 0.08, 0.55), Color("59615a"))
		MeadowGeometry.rock(parent, Vector3(side * 0.47, 1.08, 1.23), Vector3(0.12, 0.12, 0.05), Color("f5e5aa"))
	MeadowGeometry.box(parent, Vector3(0, 1.02, 1.22), Vector3(0.66, 0.66, 0.05), Color("343c3d"))
	for row in 7:
		MeadowGeometry.box(parent, Vector3(0, 0.76 + row * 0.085, 1.26), Vector3(0.6, 0.025, 0.04), Color("8a9398"))
	MeadowGeometry.box(parent, Vector3(0, 1.45, -0.5), Vector3(0.64, 0.12, 0.55), Color("343c3d"))
	MeadowGeometry.box(parent, Vector3(0, 1.68, -0.78), Vector3(0.64, 0.5, 0.12), Color("343c3d"))
	var wheel := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.19
	torus.outer_radius = 0.23
	torus.rings = 16
	torus.ring_segments = 6
	torus.material = MeadowGeometry.material(Color("343c3d"))
	wheel.mesh = torus
	wheel.position = Vector3(0, 1.62, 0.26)
	wheel.rotation.x = 0.65
	parent.add_child(wheel)
	MeadowGeometry.box(parent, Vector3(0, 1.42, 0.38), Vector3(0.055, 0.4, 0.055), Color("59615a"))
