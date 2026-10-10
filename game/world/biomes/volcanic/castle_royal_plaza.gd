class_name CastleRoyalPlaza
extends RefCounted
## Rooftop royal courtyard: open sky, gold mosaics, throne and lava braziers.

static func build(parent: Node3D) -> Node3D:
	var plaza := Node3D.new()
	plaza.name = "KingLavaPlaza"
	plaza.position.y = 24
	parent.add_child(plaza)
	CastleGeometry.solid(plaza, Vector3(0, -0.25, 0), Vector3(54, 0.5, 54), Color("987a66"))
	for side in [-1.0, 1.0]:
		CastleGeometry.solid(plaza, Vector3(side * 26.5, 1, 0), Vector3(1, 2, 54), Color("57414b"))
		for x in [-15.0, 15.0]:
			CastleGeometry.solid(plaza, Vector3(x, 1, side * 26.5), Vector3(24, 2, 1), Color("57414b"))
		for i in 14:
			CastleMaterials.box(plaza, Vector3(side * 26.5, 2.4, -25 + i * 4), Vector3(1.3, 1.1, 1.5), Color("b69062"))
	for i in 12:
		var angle := i * TAU / 12
		var tile := MeadowGeometry.box(plaza, Vector3(cos(angle) * 10, 0.03, sin(angle) * 10), Vector3(1.5, 0.06, 1.5), Color("e7b760"))
		tile.rotation.y = angle
		tile.material_override = CastleMaterials.metal(Color("a88a58"), 0.4)
	var carpet := MeadowGeometry.box(plaza, Vector3(0, 0.03, -6), Vector3(4.5, 0.06, 34), Color.WHITE)
	carpet.material_override = CastleMaterials.cloth()
	CastleGeometry.solid(plaza, Vector3(0, 2.6, 22), Vector3(4, 5.2, 1.1), Color("4c303b"))
	for x in [-2.3, 2.3]:
		var pillar := CastleGeometry.solid(plaza, Vector3(x, 2.5, 23), Vector3(0.65, 5, 2.8), Color("e2ae58"))
		pillar.material_override = CastleMaterials.ornament("bronze")
	for at in [Vector3(-12, 0, 12), Vector3(12, 0, 12), Vector3(-12, 0, -12), Vector3(12, 0, -12)]:
		CastleMaterials.box(plaza, at + Vector3.UP * 0.8, Vector3(1.8, 1.6, 1.8), Color("47343c"))
		var flame := MeadowGeometry.box(plaza, at + Vector3.UP * 1.7, Vector3(1.5, 0.22, 1.5), Color.WHITE)
		var material := ShaderMaterial.new()
		material.shader = preload("res://game/world/biomes/volcanic/lava.gdshader")
		flame.material_override = material
	for x in [-18.0, 18.0]:
		for z in [-16.0, 16.0]:
			MeadowGeometry.box(plaza, Vector3(x, 0.055, z), Vector3(4.5, 0.1, 4.5), Color("61c7d8"))
			for side in [-1.0, 1.0]:
				CastleMaterials.box(plaza, Vector3(x + side * 2.4, 0.15, z), Vector3(0.3, 0.3, 5.1), Color("bca786"), true)
				CastleMaterials.box(plaza, Vector3(x, 0.15, z + side * 2.4), Vector3(5.1, 0.3, 0.3), Color("bca786"), true)
			CastleGeometry.title(plaza, Vector3(x, 1.0, z), "COOLING SPRING", 18)
	CastleGeometry.title(plaza, Vector3(0, 5.7, 22.8), "KING LAVA\nOld master of Tofufu", 34)
	CastlePlazaDetails.build(plaza)
	return plaza
