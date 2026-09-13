class_name FarmCombatGrounds
extends RefCounted
## Authored open spaces and wayfinding; app composition places combat actors.

const CAMPS: Array[Vector2] = [Vector2(-26, 3), Vector2(25, -29), Vector2(25, 31)]
const DUMMIES: Array[Vector2] = [Vector2(16.8, 12), Vector2(19.3, 12), Vector2(21.8, 12)]
const VILLAGE: Rect2 = Rect2(15, -21, 24, 44)

static func is_clearing(x: float, z: float) -> bool:
	for center in CAMPS:
		if Vector2(x, z).distance_to(center) < 7.0:
			return true
	return false

static func build(parent: Node3D, terrain: FarmTerrain) -> void:
	for i in CAMPS.size():
		var center := CAMPS[i]
		MeadowGeometry.signpost(parent, terrain.point(center.x - 4.5, center.y + 5), "SNAIL GROUNDS · +25 EXP")
		for side in [-1.0, 1.0]:
			var at := terrain.point(center.x + side * 5.2, center.y - 3)
			MeadowGeometry.box(parent, at + Vector3.UP * 1.1, Vector3(0.14, 2.2, 0.14), Color("806248"))
			MeadowGeometry.box(parent, at + Vector3(0.35, 1.85, 0), Vector3(0.75, 0.6, 0.08), Color("b97568"))
	FarmBuildings.fence(parent, terrain, Vector2(16, 10), Vector2(22.5, 10))
	MeadowGeometry.signpost(parent, terrain.point(19.3, 15.6), "PRACTICE YARD · NO EXP")
	MeadowGeometry.signpost(parent, terrain.point(22, -20), "NORTH · SNAIL GROUNDS")
	MeadowGeometry.signpost(parent, terrain.point(22, 23), "SOUTH · SNAIL GROUNDS")
