class_name OceanCreatureArt
extends RefCounted
## Recognizable silhouettes: reef fish, sea turtles, rays and glowing jellyfish.

static func build(kind: int, color: Color) -> Node3D:
	var animal := Node3D.new()
	match kind:
		0:
			ellipsoid(animal, Vector3.ZERO, Vector3(0.62, 0.26, 0.20), color)
			var tail := MeadowGeometry.box(animal, Vector3(-0.38, 0, 0), Vector3(0.18, 0.32, 0.08), color.darkened(0.15))
			tail.name = "Tail"
			ellipsoid(animal, Vector3(0.22, 0.055, 0.10), Vector3(0.055, 0.055, 0.025), Color("192b33"))
		1:
			ellipsoid(animal, Vector3.ZERO, Vector3(1.15, 0.42, 0.85), Color("6e9d74"))
			ellipsoid(animal, Vector3(0.67, 0, 0), Vector3(0.38, 0.26, 0.28), Color("a8bb83"))
			for side in [-1.0, 1.0]:
				var fin := ellipsoid(animal, Vector3(0.15, -0.10, side * 0.6), Vector3(0.6, 0.10, 0.44), Color("abc88e"))
				fin.name = "FinLeft" if side < 0 else "FinRight"
		2:
			ellipsoid(animal, Vector3.ZERO, Vector3(1.0, 0.20, 1.5), Color("537e96"))
			MeadowGeometry.box(animal, Vector3(-0.85, 0, 0), Vector3(1.5, 0.06, 0.06), Color("537e96"))
			for side in [-1.0, 1.0]:
				var fin := ellipsoid(animal, Vector3(0, 0, side * 0.65), Vector3(0.95, 0.08, 0.9), Color("7dabc2"))
				fin.name = "FinLeft" if side < 0 else "FinRight"
		3:
			var bell := ellipsoid(animal, Vector3.ZERO, Vector3(0.65, 0.36, 0.65), color)
			var glow := bell.material_override as StandardMaterial3D
			glow.emission_enabled = true
			glow.emission = color * 0.22
			for strand in 5:
				var angle := strand * TAU / 5.0
				MeadowGeometry.box(animal, Vector3(cos(angle) * 0.18, -0.40, sin(angle) * 0.18), Vector3(0.035, 0.7, 0.035), color.lightened(0.2))
	return animal

static func ellipsoid(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	shape.mesh = sphere
	shape.material_override = MeadowGeometry.material(color)
	shape.position = at
	shape.scale = size
	shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shape)
	return shape
