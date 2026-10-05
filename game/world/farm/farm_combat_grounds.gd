class_name FarmCombatGrounds
extends RefCounted
## Authored open spaces and wayfinding; app composition places combat actors.

const CAMPS: Array[Vector2] = [Vector2(-26, 3), Vector2(34, -68), Vector2(27, 12)]
const CAMP_ARMORED_SPAWNS: Array[Vector2] = [Vector2(-27.8, 5.5), Vector2(32.2, -65.5), Vector2(25.2, 14.5)]
const FOREST_ARMORED_SPAWNS: Array[Vector2] = [
	Vector2(-62, -58), Vector2(-34, -63), Vector2(0, -64), Vector2(44, -70),
	Vector2(80, -61), Vector2(79, -17), Vector2(66, 25), Vector2(57, 55),
	Vector2(22, 63), Vector2(-12, 62), Vector2(-48, 57), Vector2(-68, 23),
	Vector2(-72, -36), Vector2(-46, -39), Vector2(-10, -40), Vector2(2, -48),
	Vector2(80, -36), Vector2(74, 1), Vector2(82, 12), Vector2(73, 46),
	Vector2(46, 35), Vector2(0, 41), Vector2(-31, 38), Vector2(-65, 45),
]
const DUMMIES: Array[Vector2] = [Vector2(16.8, 12), Vector2(19.3, 12), Vector2(21.8, 12)]
const BEE_SPAWNS: Array[Vector2] = [Vector2(-8, 70), Vector2(4, 73), Vector2(-7, 86), Vector2(5, 89)]
const VILLAGE_BEE_MARGIN: float = 20.0
const VILLAGE: Rect2 = MeadowVillage.BOUNDS
const VILLAGE_SNAIL_MARGIN: float = 1.5
const DUEL_CLEARING_CENTER := Vector2(70, 33)
const DUEL_CLEARING_HALF_SIZE := Vector2(28, 23)

static func is_camp_armored_spawn(at: Vector2) -> bool:
	for spawn in CAMP_ARMORED_SPAWNS:
		if at.distance_to(spawn) < 0.05: return true
	return false

static func is_forest_clearing(x: float, z: float) -> bool:
	for spawn in FOREST_ARMORED_SPAWNS:
		if Vector2(x, z).distance_to(spawn) < 9.0: return true
	return false

static func is_clearing(x: float, z: float) -> bool:
	for spawn in BEE_SPAWNS:
		if Vector2(x, z).distance_to(spawn) < 9.0: return true
	if absf(x - DUEL_CLEARING_CENTER.x) <= DUEL_CLEARING_HALF_SIZE.x and absf(z - DUEL_CLEARING_CENTER.y) <= DUEL_CLEARING_HALF_SIZE.y: return true
	for center in CAMPS:
		if Vector2(x, z).distance_to(center) < 7.0:
			return true
	return is_forest_clearing(x, z)

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
