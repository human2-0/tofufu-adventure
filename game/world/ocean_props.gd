class_name OceanProps
extends RefCounted
## Hand-built underwater silhouettes without an external art dependency.

static func coral(parent: Node3D, at: Vector3, size: float, color: Color) -> void:
	for i in 5:
		var angle := i * TAU / 5.0
		var branch := MeadowGeometry.box(parent, at + Vector3(cos(angle) * size * 0.24, size * 0.36, sin(angle) * size * 0.24), Vector3(size * 0.16, size * 0.82, size * 0.16), color)
		branch.rotation.z = sin(angle) * 0.55

static func kelp(parent: Node3D, at: Vector3, height: float) -> void:
	for i in 3:
		var blade := MeadowGeometry.box(parent, at + Vector3((i - 1) * 0.18, height * 0.5, 0), Vector3(0.18, height, 0.09), Color("397d66"))
		blade.rotation.z = (i - 1) * 0.25

static func sea_rock(parent: Node3D, at: Vector3, size: Vector3) -> void:
	MeadowGeometry.rock(parent, at + Vector3.UP * size.y * 0.5, size, Color("3d6570"), true)

static func fish(parent: Node3D, at: Vector3, color: Color) -> void:
	MeadowGeometry.rock(parent, at, Vector3(0.36, 0.18, 0.16), color)
	var tail := MeadowGeometry.box(parent, at + Vector3(-0.33, 0, 0), Vector3(0.18, 0.28, 0.06), color)
	tail.rotation.z = 0.6
