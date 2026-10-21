class_name GigalopolisStreets
extends RefCounted
## Deliberate open lanes, shaded market squares and small coherent street details.

static func build(parent: Node3D) -> void:
	for x in range(90, 240, 12):
		GigalopolisGeometry.lamp(parent, GigalopolisTerrain.point(Vector2(x, 12)))
	for z in range(64, 180, 16):
		for x in [154.0, 208.0]:
			var at := GigalopolisTerrain.point(Vector2(x, z))
			GigalopolisGeometry.lamp(parent, at)
			if int(z) % 32 == 0: _bench(parent, at + Vector3(-2, 0, 3))
	for at: Vector2 in [Vector2(176, 68), Vector2(176, 110), Vector2(216, 150)]:
		_market(parent, GigalopolisTerrain.point(at))
	for at: Vector2 in [Vector2(139, 92), Vector2(138, 148), Vector2(178, 186), Vector2(194, 302)]:
		var point := GigalopolisTerrain.point(at)
		GigalopolisGeometry.box(parent, point + Vector3.UP * 0.6, Vector3(3, 1.2, 3), "stone", true)
		GigalopolisGeometry.box(parent, point + Vector3.UP * 1.2, Vector3(2.7, 0.12, 2.7), "dark")
		MeadowGeometry.rock(parent, point + Vector3.UP * 1.4, Vector3(1.2, 1, 1.2), Color("748b6b"))
	for index in GigalopolisTerrain.SPINE.size() - 1:
		var start := GigalopolisTerrain.SPINE[index]
		var finish := GigalopolisTerrain.SPINE[index + 1]
		var count := ceili(start.distance_to(finish) / 15)
		promenade(parent, start, finish)
		for step in count:
			var at := start.lerp(finish, float(step) / count)
			GigalopolisGeometry.lamp(parent, GigalopolisTerrain.point(at + Vector2(-5, 0)))
	promenade(parent, GigalopolisTerrain.BEACH_LINK[0], GigalopolisTerrain.BEACH_LINK[1])
	for at: Vector2 in [Vector2(225, 292), Vector2(232, 324), Vector2(232, 352)]:
		var point := GigalopolisTerrain.point(at)
		GigalopolisGeometry.box(parent, point + Vector3.UP * 0.45, Vector3(2.8, 0.9, 2.8), "metal", true)
		GigalopolisGeometry.box(parent, point + Vector3.UP * 1.0, Vector3(3.3, 0.2, 3.3), "paving")
	MeadowGeometry.signpost(parent, GigalopolisTerrain.point(Vector2(154, 64)), "SOUTH WARDS · SHORE  ↓")
	MeadowGeometry.signpost(parent, GigalopolisTerrain.point(Vector2(166, 178)), "SHORE CAMP · VOLCANO WATCH  ↓")
	MeadowGeometry.signpost(parent, GigalopolisTerrain.point(Vector2(212, 314)), "EMBERCROWN BEACH  >")
	MeadowGeometry.signpost(parent, GigalopolisTerrain.point(Vector2(236, 320)), "<  GIGALOPOLIS · COAST ROAD")
	_clock(parent, GigalopolisTerrain.point(Vector2(176, 90)))

static func promenade(parent: Node3D, start: Vector2, finish: Vector2, half_width: float = 2.8) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side := (finish - start).normalized().orthogonal() * half_width
	var count := ceili(start.distance_to(finish) / 2)
	for index in count:
		var a := start.lerp(finish, float(index) / count)
		var b := start.lerp(finish, float(index + 1) / count)
		for at: Vector2 in [a - side, a + side, b - side, b - side, a + side, b + side]:
			surface.add_vertex(GigalopolisTerrain.point(at, 0.055))
	surface.generate_normals()
	var path := MeshInstance3D.new()
	path.mesh = surface.commit()
	path.material_override = GigalopolisMaterials.surface("paving")
	path.set_meta("static_ornament_mesh", true)
	parent.add_child(path)

static func _clock(parent: Node3D, at: Vector3) -> void:
	GigalopolisGeometry.box(parent, at + Vector3.UP * 5, Vector3(3.2, 10, 3.2), "stone", true)
	GigalopolisGeometry.box(parent, at + Vector3.UP * 10, Vector3(4.1, 0.5, 4.1), "metal")
	GigalopolisGeometry.box(parent, at + Vector3(0, 8, 1.65), Vector3(2.3, 2.3, 0.15), "dark")
	GigalopolisGeometry.box(parent, at + Vector3(0, 8.4, 1.76), Vector3(0.1, 0.9, 0.08), "brass")
	GigalopolisGeometry.box(parent, at + Vector3(0.4, 8, 1.77), Vector3(0.9, 0.1, 0.08), "brass")

static func _bench(parent: Node3D, at: Vector3) -> void:
	GigalopolisGeometry.box(parent, at + Vector3.UP * 0.4, Vector3(2.8, 0.8, 0.7), "stone", true)
	GigalopolisGeometry.box(parent, at + Vector3(0, 0.95, -0.35), Vector3(2.8, 0.6, 0.15), "metal", true)

static func _market(parent: Node3D, at: Vector3) -> void:
	for side in [-1.0, 1.0]:
		var center := at + Vector3(side * 5, 0, 0)
		for x in [-2.0, 2.0]:
			GigalopolisGeometry.box(parent, center + Vector3(x, 1.6, -1), Vector3(0.16, 3.2, 0.16), "metal", true)
		GigalopolisGeometry.box(parent, center + Vector3(0, 3.1, 0), Vector3(4.8, 0.18, 4), "canvas")
		GigalopolisGeometry.box(parent, center + Vector3(0, 0.55, -0.5), Vector3(3.8, 1.1, 1.2), "metal", true)
		for x in [-1.2, 0.0, 1.2]:
			GigalopolisGeometry.box(parent, center + Vector3(x, 1.3, -0.5), Vector3(0.8, 0.4, 0.8), "canvas")
	_bench(parent, at + Vector3(0, 0, 4))
