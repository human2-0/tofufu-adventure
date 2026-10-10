class_name MeadowBuildingDetails
extends RefCounted
## Authored joinery, roof edges and hardware within existing building footprints.

static func house(parent: Node3D) -> void:
	MeadowSurfaces.apply(parent.get_child(1), "brick")
	for x in [-3.1, 3.1]:
		_frame(parent, Vector3(x, 1.65, 3.64), Vector2(1.18, 1.25), Color("f4e4bd"))
		for side in [-1.0, 1.0]:
			var shutter := MeadowGeometry.box(parent, Vector3(x + side * 0.86, 1.65, 3.62), Vector3(0.46, 1.18, 0.13), Color("725946"))
			shutter.rotation.y = side * 0.13
			for row in 5:
				MeadowGeometry.box(parent, Vector3(x + side * 0.86, 1.25 + row * 0.2, 3.72), Vector3(0.4, 0.035, 0.06), Color("8d694e"))
	_frame(parent, Vector3(0, 1.04, 3.66), Vector2(1.35, 2.12), Color("e5d5ad"))
	for y in [0.55, 1.43]:
		_frame(parent, Vector3(0, y, 3.67), Vector2(0.76, 0.58), Color("8d694e"))
	for z in [-3.54, 3.54]:
		var gable := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(10, 2.6, 0.16)
		mesh.material = MeadowSurfaces.material("timber")
		gable.mesh = mesh
		gable.position = Vector3(0, 4.95, z)
		parent.add_child(gable)
		for side in [-1.0, 1.0]:
			_beam(parent, Vector3(side * 5.6, 3.55, z * 1.18), Vector3(0, 6.23, z * 1.18), 0.16, Color("725946"))
	for side in [-1.0, 1.0]:
		var fascia := MeadowGeometry.box(parent, Vector3(side * 5.06, 3.67, 0), Vector3(0.18, 0.68, 7.8), Color("493024"))
		MeadowSurfaces.apply(fascia, "roof")
		MeadowGeometry.box(parent, Vector3(side * 5.5, 3.48, 0), Vector3(0.15, 0.15, 8.1), Color("555b55"))
		MeadowGeometry.box(parent, Vector3(side * 5.3, 1.7, -3.55), Vector3(0.1, 3.4, 0.1), Color("555b55"))
	MeadowGeometry.box(parent, Vector3(2.7, 5.92, -1.54), Vector3(0.84, 0.18, 0.86), Color("555b55"))
	MeadowSurfaces.apply_tree(parent)

static func shell(parent: Node3D, size: Vector3, wood: bool, roofs: Array[MeshInstance3D], walls: Array[MeshInstance3D]) -> void:
	for wall in walls: MeadowSurfaces.apply(wall, "timber" if wood else "concrete")
	for roof in roofs: MeadowSurfaces.apply(roof, "roof")
	# Trim follows the same cutaway group as walls, avoiding a floating facade indoors.
	for z in [-size.z / 2 - 0.16, size.z / 2 + 0.16]:
		for side in [-1.0, 1.0]:
			var eave := MeadowGeometry.box(parent, Vector3(side * size.x / 4, size.y + 0.65, z), Vector3(size.x / 2 + 0.8, 0.2, 0.14), Color("75543b"))
			eave.rotation.z = -side * 0.20
			eave.set_meta("cutaway_ornament", true)
			roofs.append(eave)
	if wood:
		for z in [-size.z / 2 + 0.4, size.z / 2 - 0.4]:
			for side in [-1.0, 1.0]:
				var at := Vector3(side * (size.x / 2 - 0.22), size.y / 2, z)
				var post := MeadowGeometry.box(parent, at, Vector3(0.22, size.y, 0.22), Color("75543b"))
				post.set_meta("cutaway_ornament", true)
				walls.append(post)
		for side in [-1.0, 1.0]:
			var x: float = side * (size.x / 2 - 0.2)
			var brace := _beam(parent, Vector3(x, 1.1, -size.z / 2 + 0.55), Vector3(x, size.y - 0.15, -size.z / 2 + 2.1), 0.16, Color("75543b"))
			brace.set_meta("cutaway_ornament", true)
			walls.append(brace)
	MeadowSurfaces.apply_tree(parent)

static func chest(parent: Node3D, index: int) -> void:
	var at := MeadowBarn.bay_position(index)
	var front := MeadowBarn.front(index)
	for z in [-0.28, 0.28]:
		MeadowGeometry.box(parent, at + Vector3(0, 0.985, z), Vector3(1.3, 0.026, 0.08), Color("59615a"))
		MeadowGeometry.box(parent, at + front * 0.64 + Vector3(0, 0.43, z), Vector3(0.026, 0.83, 0.08), Color("59615a"))
	for z in [-0.32, 0.32]:
		for y in [0.13, 0.75]:
			MeadowGeometry.rock(parent, at + front * 0.66 + Vector3(0, y, z), Vector3(0.027, 0.027, 0.027), Color("cfb570"))
	MeadowGeometry.box(parent, at + front * 0.685 + Vector3.UP * 0.51, Vector3(0.045, 0.09, 0.09), Color("50483a"))

static func _frame(parent: Node3D, at: Vector3, size: Vector2, color: Color) -> void:
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(parent, at + Vector3(side * size.x / 2, 0, 0), Vector3(0.09, size.y, 0.08), color)
		MeadowGeometry.box(parent, at + Vector3(0, side * size.y / 2, 0), Vector3(size.x + 0.09, 0.09, 0.08), color)

static func _beam(parent: Node3D, start: Vector3, end: Vector3, width: float, color: Color) -> MeshInstance3D:
	var view := MeadowGeometry.box(parent, (start + end) * 0.5, Vector3(width, width, start.distance_to(end)), color)
	view.look_at(end, Vector3.UP)
	return view
