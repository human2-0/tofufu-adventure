class_name DesertWorld
extends Node3D
## Reachable southern transition: dunes, a navigable caravan route and oasis landmark.

var farm: FarmTerrain

func _ready() -> void:
	name = "DesertWorld"
	DesertTerrain.build(self, farm)
	_entrance()
	_oasis()
	_landmarks()
	_scatter()
	_boundaries()

func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, DesertTerrain.height_at(x, z, farm) + lift, z)

func _authored_point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return point(x * 2.0, DesertTerrain.SOUTH_START + (z - 42.0) * 2.0, lift)

func is_water(at: Vector3) -> bool:
	return at.z >= DesertTerrain.SOUTH_START and RiverCourse.contains(at)

func _entrance() -> void:
	MeadowGeometry.signpost(self, _authored_point(0, 45), "SUNSAND DESERT  v")
	for x in [-9.0, 10.0]:
		DesertProps.sandstone(self, _authored_point(x, 47), Vector3(5.2, 2.8, 4.4))

func _oasis() -> void:
	for i in 15:
		var angle := i * TAU / 15.0
		var at := RiverCourse.OASIS + Vector2(cos(angle) * 12.7, sin(angle) * 10.7)
		if at.y < 141.0 and absf(at.x + 38.0) < 5.0: continue
		MeadowGeometry.rock(self, point(at.x, at.y, 0.16), Vector3(0.6, 0.28, 0.46), Color("b6a581"))
	for at in [Vector2(-51, 144), Vector2(-26, 147), Vector2(-43, 161), Vector2(-29, 158)]:
		DesertProps.palm(self, point(at.x, at.y), 5.5, at.y)
		DesertProps.yucca(self, point(at.x + 1.2, at.y + 0.6), 1.0)
	MeadowGeometry.signpost(self, point(-23, 160), "MOONWELL OASIS")

func _landmarks() -> void:
	# Wind-carved columns and a small abandoned caravan rest make the crossing memorable.
	for at in [Vector2(21, 63), Vector2(24, 66), Vector2(18, 67)]:
		DesertProps.sandstone(self, _authored_point(at.x, at.y), Vector3(5.2, 4.2, 4.4))
	var camp := _authored_point(14, 91)
	MeadowGeometry.box(self, camp + Vector3.UP * 0.65, Vector3(4.4, 1.3, 3.2), Color("a85e45"), true)
	MeadowGeometry.box(self, camp + Vector3.UP * 1.38, Vector3(4.8, 0.16, 3.6), Color("d8a866"))
	for x in [-1.3, 1.3]:
		MeadowGeometry.rock(self, camp + Vector3(x, 0.38, 2.0), Vector3(0.45, 0.36, 0.45), Color("a87241"), true)
	MeadowGeometry.signpost(self, _authored_point(2, 102), "JADEWILD JUNGLE · LV 8  v")

func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7018
	for i in 112:
		var x := rng.randf_range(-74.0, 74.0)
		var z := rng.randf_range(96.0, 206.0)
		if DesertTerrain.trail_distance(x, z) < 4.2 or RiverCourse.bank_distance(x, z) < 4.5 or Vector2(x - 14, z - 91).length() < 5.5:
			continue
		if i % 5 == 0:
			DesertProps.cactus(self, point(x, z), rng.randf_range(2.0, 4.6))
		elif i % 2 == 0:
			DesertProps.yucca(self, point(x, z), rng.randf_range(0.7, 1.4))
		else:
			DesertProps.dry_shrub(self, point(x, z), rng.randf_range(0.55, 1.05))
		if i % 4 == 0:
			MeadowGeometry.rock(self, point(x + 1.1, z, 0.32), Vector3(0.8, 0.45, 0.7), Color("aa7040"), true)

func _boundaries() -> void:
	for spec in [Vector4(-81, 150, 1, 136), Vector4(81, 150, 1, 136)]:
		var wall := MeadowGeometry.box(self, Vector3(spec.x, 35, spec.y), Vector3(spec.z, 100, spec.w), Color.WHITE, true)
		wall.visible = false
