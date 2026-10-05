class_name CastleExterior
extends RefCounted
## Obsidian buttresses, crenellations, royal banners and four crowned corner towers.

static func build(parent: Node3D) -> Node3D:
	var facade := Node3D.new()
	facade.name = "CastleFacade"
	parent.add_child(facade)
	for x in [-27.5, 27.5]:
		for z in [-27.5, 27.5]: _tower(facade, Vector3(x, 0, z))
	for side in [-1.0, 1.0]:
		for i in 9:
			var z := -24.0 + i * 6.0
			MeadowGeometry.box(facade, Vector3(side * 27.6, 12, z), Vector3(1.5, 24, 1.4), Color("36303a"))
			for y in [5.0, 13.0, 21.0]:
				MeadowGeometry.box(facade, Vector3(side * 28.4, y, z), Vector3(0.1, 2.8, 1.1), Color("f1a65b"))
		for x in [-18.0, 18.0]:
			MeadowGeometry.box(facade, Vector3(x, 15, side * 27.6), Vector3(3.5, 8, 0.12), Color("9c3537"))
			MeadowGeometry.box(facade, Vector3(x, 15, side * 27.75), Vector3(0.65, 4, 0.08), Color("f8bf65"))
	CastleGeometry.title(facade, Vector3(0, 5.6, 28.0), "TOFUFU CASTLE", 48)
	return facade

static func _tower(parent: Node3D, at: Vector3) -> void:
	MeadowGeometry.box(parent, at + Vector3.UP * 13, Vector3(7, 26, 7), Color("493942"))
	for side in [-1.0, 1.0]:
		for i in 4:
			MeadowGeometry.box(parent, at + Vector3(side * 3.5, 27, -3 + i * 2), Vector3(1.5, 2.4, 1.4), Color("96765c"))
	var roof := CylinderMesh.new()
	roof.top_radius = 0.1
	roof.bottom_radius = 4.7
	roof.height = 8
	roof.radial_segments = 8
	roof.material = MeadowGeometry.material(Color("4b333d"))
	var instance := MeshInstance3D.new()
	instance.mesh = roof
	instance.position = at + Vector3.UP * 31
	parent.add_child(instance)
