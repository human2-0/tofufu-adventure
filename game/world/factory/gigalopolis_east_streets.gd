class_name GigalopolisEastStreets
extends RefCounted
## Broad connected avenues, planted courts and a southern shoreline promenade.

static func build(parent: Node3D) -> void:
	for z: float in [6, 110, 158]:
		GigalopolisStreets.promenade(parent, Vector2(242, z), Vector2(636, z), 4.2)
		for x in range(252, 637, 24):
			var lamp_x := float(x)
			for avenue in GigalopolisTerrain.AVENUES:
				if absf(lamp_x - avenue) < 4.5: lamp_x = avenue - 5.5
			GigalopolisGeometry.lamp(parent, GigalopolisTerrain.point(Vector2(lamp_x, z + 7)))
	for x in GigalopolisTerrain.AVENUES:
		GigalopolisStreets.promenade(parent, Vector2(x, -40), Vector2(x, 176), 3.4)
		for z in range(28, 180, 32):
			GigalopolisGeometry.lamp(parent, GigalopolisTerrain.point(Vector2(x - 5, z)))
	for x in GigalopolisEast.COLUMNS:
		for z: float in [22, 172]:
			var at := GigalopolisTerrain.point(Vector2(x - 10, z))
			GigalopolisGeometry.box(parent, at + Vector3.UP * 0.4, Vector3(4, 0.8, 3), "stone", true)
			GigalopolisGeometry.box(parent, at + Vector3.UP * 0.84, Vector3(3.6, 0.1, 2.6), "dark")
			MeadowGeometry.rock(parent, at + Vector3.UP * 1.5, Vector3(1.7, 1.5, 1.2), Color("7f9a71"))
			GigalopolisGeometry.box(parent, GigalopolisTerrain.point(Vector2(x + 7, z)) + Vector3.UP * 0.4, Vector3(3.8, 0.8, 0.8), "stone", true)
	for at: Vector2 in [Vector2(250, 14), Vector2(378, 118), Vector2(632, 166)]:
		MeadowGeometry.signpost(parent, GigalopolisTerrain.point(at), "GIGALOPOLIS · EASTERN QUARTERS  >")
