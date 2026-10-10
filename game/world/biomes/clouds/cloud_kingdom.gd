class_name CloudKingdom
extends RefCounted
## Open sky palace, royal bazaar, blossom gardens and lamps along joined cloud paths.

static func build(parent: Node3D) -> void:
	_pavilion(parent, Vector2(-8, 265), Vector2(13, 9), Color("c0b3e0"))
	_pavilion(parent, Vector2(4, 340), Vector2(12, 10), Color("b3cde8"))
	_stall(parent, Vector2(43, 285), Color("8bc6bc"))
	_stall(parent, Vector2(34, 299), Color("e3b2cf"))
	_fountain(parent, Vector2(-55, 292))
	_fountain(parent, Vector2(50, 332))
	for at in [Vector2(-65, 301), Vector2(-46, 308), Vector2(-44, 337), Vector2(0, 350), Vector2(16, 346), Vector2(54, 340)]:
		_tree(parent, at)
	CloudPathDetails.build(parent)
	CloudCourtyards.build(parent)
	CloudOrnaments.build(parent)
	MeadowGeometry.signpost(parent, CloudTerrain.point(29, 284), "ROYAL OUTFITTER →\nNIMBUS · GEAR & EQUIPMENT")
	MeadowGeometry.signpost(parent, CloudTerrain.point(-38, 288), "BLOSSOM GARDENS\nTHE LITTLE ANGELS' HOME")
	MeadowGeometry.signpost(parent, CloudTerrain.point(8, 319), "GODFUFU'S SKY SANCTUARY ↑")

static func _pavilion(parent: Node3D, at: Vector2, size: Vector2, color: Color) -> void:
	var root := Node3D.new()
	root.position = CloudTerrain.point(at.x, at.y)
	parent.add_child(root)
	for x in [-size.x * 0.5, size.x * 0.5]:
		for z in [-size.y * 0.5, size.y * 0.5]:
			var base := CloudTerrain.height_at(at.x + x, at.y + z) - root.position.y
			var collider := MeadowGeometry.box(root, Vector3(x, base + 2.4, z), Vector3(0.7, 4.8, 0.7), Color("f1e6d2"), true)
			collider.mesh = null
			CloudTemple.column(root, Vector3(x, base, z))
	CloudTemple.roof(root, size)
	# A throne against the rear leaves a broad, flush walking court.
	var throne := MeadowGeometry.box(root, Vector3(0, 1.4, -size.y * 0.35), Vector3(2.4, 2.8, 0.5), color, true)
	throne.material_override = CloudMaterials.marble(color)
	var seat := MeadowGeometry.box(root, Vector3(0, 0.65, -size.y * 0.35 + 0.8), Vector3(2.4, 0.4, 1.3), Color.WHITE, true)
	seat.material_override = CloudMaterials.silk()
	CloudOrnaments.wreath(root, Vector3(0, 2.3, -size.y * 0.35 + 0.3), 0.65, true)

static func _stall(parent: Node3D, at: Vector2, color: Color) -> void:
	var root := Node3D.new()
	root.position = CloudTerrain.point(at.x, at.y)
	parent.add_child(root)
	for x in [-2.6, 2.6]:
		MeadowGeometry.box(root, Vector3(x, 1.8, -1), Vector3(0.2, 3.6, 0.2), Color("c7b083"), true)
	for i in 8:
		var cloth := MeadowGeometry.box(root, Vector3(-2.8 + i * 0.8, 3.7, -0.4), Vector3(0.8, 0.18, 3.7), Color.WHITE)
		cloth.material_override = CloudMaterials.silk(color.lightened(0.5) if i % 2 == 0 else Color.WHITE)
	var counter := MeadowGeometry.box(root, Vector3(0, 0.75, -1.8), Vector3(5, 1.5, 0.65), Color.WHITE, true)
	counter.material_override = CloudMaterials.marble()
	CloudCraft.box(root, Vector3(0, 1.05, -1.45), Vector3(5, 0.18, 0.03), CloudMaterials.illustrated(CloudMaterials.FRIEZE))
	for i in 4:
		var item := MeadowGeometry.box(root, Vector3(-1.7 + i * 1.1, 1.7, -1.7), Vector3(0.4, 0.22, 0.45), Color("b4cde6") if i % 2 else Color("f0d296"))
		item.rotation.z = 0.12

static func _fountain(parent: Node3D, at: Vector2) -> void:
	var root := Node3D.new()
	root.position = CloudTerrain.point(at.x, at.y)
	parent.add_child(root)
	MeadowGeometry.rock(root, Vector3.UP * 0.22, Vector3(2.1, 0.24, 2.1), Color.WHITE, true)
	for child in root.get_children():
		if child is MeshInstance3D: child.material_override = CloudMaterials.marble()
	CloudCraft.ring(root, Vector3.UP * 0.44, 2.05, 0.07, CloudMaterials.gold())
	CloudCraft.cylinder(root, Vector3.UP * 0.49, 1.7, 0.025, CloudMaterials.water())
	var pillar := MeadowGeometry.box(root, Vector3.UP, Vector3(0.45, 1.7, 0.45), Color.WHITE, true)
	pillar.material_override = CloudMaterials.marble()
	var profile: Array[Vector2] = [Vector2(0.15, 0), Vector2(0.4, 0.1), Vector2(0.85, 0.32), Vector2(0.89, 0.38)]
	CloudCraft.lathe(root, Vector3.UP * 1.8, profile, CloudMaterials.marble())
	CloudCraft.ring(root, Vector3.UP * 2.18, 0.89, 0.05, CloudMaterials.gold())
	CloudCraft.cylinder(root, Vector3.UP * 2.17, 0.82, 0.025, CloudMaterials.water())

static func _tree(parent: Node3D, at: Vector2) -> void:
	var base := CloudTerrain.point(at.x, at.y)
	MeadowGeometry.box(parent, base + Vector3.UP * 1.5, Vector3(0.5, 3, 0.5), Color("b8a2ba"), true)
	for i in 5:
		MeadowGeometry.rock(parent, base + Vector3(cos(i * 2.4) * 1.2, 3.4 + i * 0.18, sin(i * 2.4) * 1.2), Vector3(1.8, 0.9, 1.8), Color("f2c4de") if i % 2 else Color("d5cff2"))
