class_name FrostWorld
extends Node3D
## A broad snowy northern land reached by rising out of the AquaDepths.

var ocean: OceanWorld

func _ready() -> void:
	name = "FrostWorld"
	FrostTerrain.build(self, ocean)
	_entrance()
	_frozen_lake()
	_glacier_camp()
	_scatter()
	_boundaries()

func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, FrostTerrain.height_at(x, z, ocean) + lift, z)

func _entrance() -> void:
	MeadowGeometry.signpost(self, point(0, -232), "FROSTCROWN REACH  ^")
	for x in [-16.0, 16.0]: FrostProps.glacier_rock(self, point(x, -234), Vector3(5.0, 3.5, 4.6))

func _frozen_lake() -> void:
	var center := point(44, -298)
	var ice := CylinderMesh.new()
	ice.top_radius = 8.5
	ice.bottom_radius = 8.1
	ice.height = 0.14
	ice.radial_segments = 20
	ice.material = MeadowGeometry.material(Color("8bd8e5"))
	var lake := MeshInstance3D.new()
	lake.name = "MirrorIceLake"
	lake.mesh = ice
	lake.position = center + Vector3.UP * 0.15
	add_child(lake)
	for i in 12:
		var angle := i * TAU / 12.0
		FrostProps.crystal(self, center + Vector3(cos(angle) * 9.1, 0, sin(angle) * 7.8), 1.1 + (i % 3) * 0.32)
	MeadowGeometry.signpost(self, point(22, -302), "MIRROR ICE")

func _glacier_camp() -> void:
	var camp := point(-50, -332)
	MeadowGeometry.box(self, camp + Vector3.UP * 0.7, Vector3(4.8, 1.4, 3.5), Color("6d8fa6"), true)
	MeadowGeometry.box(self, camp + Vector3.UP * 1.48, Vector3(5.2, 0.16, 3.9), Color("e2f4f4"))
	for at in [Vector2(-64, -338), Vector2(-36, -342), Vector2(-56, -350)]:
		FrostProps.glacier_rock(self, point(at.x, at.y), Vector3(3.0, 5.0, 2.8))
	MeadowGeometry.signpost(self, point(-12, -354), "AURORA GLACIER")

func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9284
	for i in 128:
		var x := rng.randf_range(-132.0, 132.0)
		var z := rng.randf_range(-358.0, -232.0)
		if FrostTerrain.trail_distance(x, z) < 4.5 or Vector2(x - 44, z + 298).length() < 22.0 or Vector2(x + 50, z + 332).length() < 14.0:
			continue
		if i % 4 == 0:
			FrostProps.pine(self, point(x, z), rng.randf_range(4.5, 8.5))
		elif i % 3 == 0:
			FrostProps.crystal(self, point(x, z), rng.randf_range(1.0, 3.0))
		else:
			FrostProps.glacier_rock(self, point(x, z), Vector3(0.9, 0.7, 0.8))

func _boundaries() -> void:
	for spec in [Vector4(-141, -294, 1, 152), Vector4(141, -294, 1, 152), Vector4(0, -369, 282, 1)]:
		var wall := MeadowGeometry.box(self, Vector3(spec.x, 35, spec.y), Vector3(spec.z, 100, spec.w), Color.WHITE, true)
		wall.visible = false
