class_name CloudTrainingCourt
extends RefCounted
## Open Olympian practice terrace; the app owns targets and personal transfers.

const DUMMIES: Array[Vector2] = [Vector2(54, 374), Vector2(62, 377), Vector2(70, 374)]
const CHESTS: Array[Vector2] = [Vector2(45, 354), Vector2(49, 354), Vector2(53, 354), Vector2(57, 354)]

static func build(parent: Node3D) -> Array[Node3D]:
	var sites: Array[Node3D] = []
	MeadowGeometry.signpost(parent, CloudTerrain.point(49, 344), "CELESTIAL TRAINING TERRACE ↑\nPERSONAL DEPOSIT · PRACTICE · OPEN SKY")
	MeadowGeometry.signpost(parent, CloudTerrain.point(76, 371), "TRAINING · 500 HP\nREFILLS ON DEFEAT / EVERY 6 SECONDS")
	for at in DUMMIES:
		CloudCraft.ring(parent, CloudTerrain.point(at.x, at.y, 0.04), 2.2, 0.08, CloudMaterials.gold())
	for at in CHESTS:
		var site := Node3D.new()
		site.name = "CloudDeposit%02d" % (sites.size() + 1)
		site.position = CloudTerrain.point(at.x, at.y)
		parent.add_child(site)
		var chest := MeadowGeometry.box(site, Vector3(0, 0.5, 0), Vector3(1.6, 1.0, 0.9), Color.WHITE, true)
		chest.material_override = CloudMaterials.marble(Color("dcd7ed"))
		CloudCraft.box(site, Vector3(0, 1.04, 0), Vector3(1.75, 0.14, 1.03), CloudMaterials.gold())
		CloudCraft.box(site, Vector3(0, 0.65, 0.48), Vector3(0.22, 0.3, 0.08), CloudMaterials.gold())
		CloudCraft.box(site, Vector3(0, 0.28, 0.46), Vector3(1.5, 0.14, 0.025), CloudMaterials.illustrated(CloudMaterials.FRIEZE))
		CloudCraft.ring(site, Vector3(0, 1.32, 0), 0.42, 0.045, CloudMaterials.gold())
		sites.append(site)
	MeadowGeometry.signpost(parent, CloudTerrain.point(42, 355), "PERSONAL DEPOSIT →\nSAME CONTENTS AS MEADOW")
	# Keep the central working area clear; columns mark its outer perimeter.
	for at in [Vector2(41, 366), Vector2(81, 366), Vector2(47, 385), Vector2(77, 385)]:
		var base := CloudTerrain.point(at.x, at.y)
		CloudTemple.column(parent, base)
		CloudCraft.body(parent, base, 0.5, 4.8)
	return sites

static func dummy_figure(figure: Node3D) -> void:
	CloudCraft.cylinder(figure, Vector3.UP * 0.08, 0.55, 0.16, CloudMaterials.marble())
	CloudCraft.cylinder(figure, Vector3.UP * 0.55, 0.12, 1.0, CloudMaterials.gold())
	CloudCraft.cylinder(figure, Vector3.UP * 1.1, 0.36, 0.85, CloudMaterials.silk(Color("d7d4f0")), 0.4)
	var head := SphereMesh.new()
	head.radius = 0.32
	head.height = 0.58
	CloudCraft.view(figure, head, Vector3.UP * 1.85, CloudMaterials.marble())
	CloudCraft.ring(figure, Vector3.UP * 2.3, 0.46, 0.065, CloudMaterials.gold())
	for side in [-1.0, 1.0]:
		CloudCraft.box(figure, Vector3(side * 0.12, 1.87, 0.3), Vector3(0.05, 0.07, 0.025), CloudMaterials.marble(Color("5e618c")))
		for feather in 4:
			var wing := CloudCraft.box(figure, Vector3(side * (0.47 + feather * 0.13), 1.35 - feather * 0.08, -0.08), Vector3(0.17, 0.58 - feather * 0.08, 0.13), CloudMaterials.marble())
			wing.rotation.z = side * -0.65
	for index in 3:
		var disk := CloudCraft.cylinder(figure, Vector3(0, 1.1, 0.4 + index * 0.025), 0.27 - index * 0.085, 0.025, CloudMaterials.gold() if index % 2 == 0 else CloudMaterials.marble(Color("797bb5")))
		disk.rotation.x = PI / 2
