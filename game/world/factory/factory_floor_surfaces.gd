class_name FactoryFloorSurfaces
extends RefCounted
## Render each deck once; overlapping physics solids stay invisible and active.

static func build(parent: Node3D) -> void:
	for deck in 2:
		var height: float = deck * 4.0
		var center_z: float = -180.0 if deck == 0 else -206.0
		_plane(parent, "DeckSurface%d" % deck, Vector3(322, height, center_z), Vector2(66, 20), Color("a4aaa0"))
		# The room deck ends at x355. This extension touches its edge without overlap.
		var landing_z: float = -178.0 if deck == 0 else -208.0
		_plane(parent, "LandingSurface%d" % deck, Vector3(357, height, landing_z), Vector2(4, 6), Color("9b9d8c"))

static func hide_support(mesh: MeshInstance3D, title: String) -> void:
	mesh.name = title
	mesh.visible = false
	mesh.set_meta("factory_collision_support", true)

static func plain_material(mesh: MeshInstance3D) -> void:
	var material: StandardMaterial3D = mesh.mesh.surface_get_material(0).duplicate()
	material.next_pass = null
	mesh.material_override = material

static func _plane(parent: Node3D, title: String, at: Vector3, size: Vector2, color: Color) -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	plane.material = FactorySurfaceMaterials.material("floor", color, false)
	var surface := MeshInstance3D.new()
	surface.name = title
	surface.mesh = plane
	surface.position = at
	surface.set_meta("factory_floor_surface", true)
	surface.set_meta("factory_surface", "floor")
	parent.add_child(surface)
