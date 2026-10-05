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
			MeadowGeometry.box(plaza, Vector3(side * 26.5, 2.4, -25 + i * 4), Vector3(1.3, 1.1, 1.5), Color("b69062"))
	for i in 12:
		var angle := i * TAU / 12
		var tile := MeadowGeometry.box(plaza, Vector3(cos(angle) * 10, 0.03, sin(angle) * 10), Vector3(1.5, 0.06, 1.5), Color("e7b760"))
		tile.rotation.y = angle
	MeadowGeometry.box(plaza, Vector3(0, 0.03, -6), Vector3(4.5, 0.06, 34), Color("8e3039"))
	MeadowGeometry.box(plaza, Vector3(0, 2.6, 11), Vector3(4, 5.2, 1.1), Color("4c303b"))
	for x in [-2.3, 2.3]:
		MeadowGeometry.box(plaza, Vector3(x, 2.5, 12), Vector3(0.65, 5, 2.8), Color("e2ae58"))
	for at in [Vector3(-12, 0, 12), Vector3(12, 0, 12), Vector3(-12, 0, -12), Vector3(12, 0, -12)]:
		MeadowGeometry.box(plaza, at + Vector3.UP * 0.8, Vector3(1.8, 1.6, 1.8), Color("47343c"))
		var flame := MeadowGeometry.box(plaza, at + Vector3.UP * 1.7, Vector3(1.5, 0.22, 1.5), Color.WHITE)
		var material := ShaderMaterial.new()
		material.shader = preload("res://game/world/biomes/volcanic/lava.gdshader")
		flame.material_override = material
	CastleGeometry.title(plaza, Vector3(0, 5.7, 11.8), "KING LAVA\nOld master of Tofufu", 34)
	return plaza
