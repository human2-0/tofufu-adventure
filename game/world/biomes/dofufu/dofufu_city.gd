class_name DofufuCity
extends Node3D
## Jade Lantern: walled rival tofu settlement with accessible streets and courtyards.

const GUARDS: Array[Vector2] = [Vector2(-849, -5), Vector2(-849, 5), Vector2(-930, -49), Vector2(-920, -49)]
var terrain: DofufuTerrain
var residents: Dictionary[String, DofufuResident] = {}

func _ready() -> void:
	name = "JadeLanternCity"
	DofufuCityBuildings.build(self, terrain)
	_resident("Dofufu Master", 0, Vector2(-936, 0), "Jade Lantern will surpass Fufufarm.\nPower must be earned here.")
	_resident("Dofufu Sensei", 1, Vector2(-905, 26), "Our rival schools never stop competing.\nWatch the courtyard drills.")
	_resident("Dofufu Geji", 2, Vector2(-896, -26), "Tofufu has held first place long enough.\nThe next tournament belongs to us.")
	for i in 14:
		var x := -866 - (i % 5) * 15
		var z: float = -34 if i < 5 else 34
		if i >= 10:
			x = -922 + int((i - 10) / 2.0) * 12
			z = -1.5 if i % 2 == 0 else 1.5
		var npc := _resident("Dofufu Challenger %d" % (i + 1), 1 if i % 2 == 0 else 2, Vector2(x, z), "Strength. Skill. Victory.")
		if i >= 10:
			npc.sparring = true
			npc.facing = Vector2.UP if i % 2 else Vector2.DOWN
			npc.art.facing = npc.facing
			npc.elapsed = PI / 4 if i % 2 else 0.0
	MeadowGeometry.signpost(self, terrain.point(-843, 10), "JADE LANTERN · DOFUFU CITY\nRIVAL SCHOOLS · GUARDED GATES")
	StaticDecorationBatch.build(self)

func _resident(title: String, role: int, at: Vector2, words: String) -> DofufuResident:
	var npc := DofufuResident.new()
	npc.title = title
	npc.role = role
	npc.words = words
	npc.position = terrain.point(at.x, at.y)
	add_child(npc)
	residents[title] = npc
	return npc
