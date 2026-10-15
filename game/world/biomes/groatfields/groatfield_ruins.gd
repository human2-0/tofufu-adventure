class_name GroatfieldRuins
extends RefCounted
## Laurel shrines and groat plants, leaving each hunting lane unobstructed.

static func build(world: Groatfields) -> void:
	var ivory := Color("e3d5bc")
	var gold := Color("d9b666")
	for center in Groatfields.CAMPS:
		for side in [-1, 1]:
			var at := world.point(center.x + side * 12, center.y)
			_cylinder(world, at + Vector3.UP * 3.8, 0.6, 3.0, ivory)
			_cylinder(world, at + Vector3.UP * 5.3, 0.8, 0.25, gold)
			for flute in 8:
				var angle := flute * TAU / 8
				var offset := Vector3(cos(angle), 0, sin(angle)) * 0.53
				_cylinder(world, at + offset + Vector3.UP * 3.8, 0.08, 2.8, Color("baaed0"))
		var shrine := world.point(center.x, center.y + 16)
		MeadowGeometry.box(world, shrine + Vector3.UP * 0.12, Vector3(8, 0.24, 3), ivory)
		MeadowGeometry.rock(world, shrine + Vector3.UP * 1.2, Vector3(1.2, 1.2, 1.2), gold)
	for i in 70:
		var z := 356.0 + i * 1.65
		var x := (-1.0 if i % 2 == 0 else 1.0) * (7.0 + i % 6 * 0.65)
		var at := world.point(x, z)
		_cylinder(world, at + Vector3.UP * 0.25, 0.035, 0.5, Color("8b9b81"))
		for grain in 3:
			var offset := Vector3((grain - 1) * 0.12, 0.45 + grain % 2 * 0.12, 0)
			MeadowGeometry.rock(world, at + offset, Vector3(0.13, 0.18, 0.12), gold)
	for side in [-1, 1]:
		var at := world.point(side * 7, 345)
		MeadowGeometry.box(world, at + Vector3.UP * 2.7, Vector3(1.4, 5.4, 1.4), ivory, true)
	MeadowGeometry.box(world, world.point(0, 345, 5.4), Vector3(15.4, 0.6, 1.6), gold)

static func _cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.material = MeadowGeometry.material(color)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position = at
	parent.add_child(view)
