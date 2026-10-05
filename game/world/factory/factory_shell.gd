class_name FactoryShell
extends RefCounted
## Fixed envelope and collision ledges. Mesh visibility never controls physics.

static func build(parent: Node3D, cutaway_meshes: Array[MeshInstance3D]) -> void:
	# All seams overlap so the player capsule cannot find a zero-width edge.
	var foundation := MeadowGeometry.box(parent, Vector3(324, -0.45, -193), Vector3(72, 0.9, 47), Color("626f69"), true)
	FactoryFloorSurfaces.hide_support(foundation, "FoundationCollision")
	_add(parent, cutaway_meshes, Vector3(324, 10.1, -193), Vector3(72, 0.6, 47), Color("3b5957"))
	for z in [-216.3, -169.7]:
		_add(parent, cutaway_meshes, Vector3(324, 4.85, z), Vector3(72, 10.3, 0.8), Color("607e78"))
	for x in [288.7, 359.3]:
		_add(parent, cutaway_meshes, Vector3(x, 4.85, -193), Vector3(0.8, 10.3, 47), Color("607e78"))
	# A second catch floor beneath the visible foundation handles tiny seam errors.
	var catch := MeadowGeometry.box(parent, Vector3(324, -2.0, -193), Vector3(76, 0.6, 51), Color("626f69"), true)
	FactoryFloorSurfaces.hide_support(catch, "CatchFloorCollision")

static func _add(parent: Node3D, cutaway_meshes: Array[MeshInstance3D], at: Vector3, size: Vector3, color: Color) -> void:
	var visual := MeadowGeometry.box(parent, at, size, color, true)
	cutaway_meshes.append(visual)
