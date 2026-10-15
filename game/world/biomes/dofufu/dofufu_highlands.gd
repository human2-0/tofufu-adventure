class_name DofufuHighlands
extends Node3D
## Continuous mountain passage and the rival Jade Lantern city.

var farm: FarmTerrain
var terrain: DofufuTerrain
var city: DofufuCity
var retreat: MountainRetreat

func _ready() -> void:
	name = "DofufuHighlands"
	terrain = DofufuTerrain.new(farm)
	terrain.build(self)
	DofufuNature.build(self, terrain)
	retreat = MountainRetreat.new()
	retreat.terrain = terrain
	add_child(retreat)
	city = DofufuCity.new()
	city.terrain = terrain
	add_child(city)
	for x in [-130.0, -300.0, -500.0, -700.0, -830.0]:
		var at := terrain.trail_point(x)
		MeadowGeometry.signpost(self, at + Vector3(0, 0, 7), "< JADE LANTERN CITY\nWESTERN MOUNTAIN TRAIL")
	for spec in [Vector4(-980, 0, 1, 360), Vector4(-545, -180, 870, 1), Vector4(-545, 180, 870, 1)]:
		var edge := MeadowGeometry.box(self, Vector3(spec.x, 60, spec.y), Vector3(spec.z, 160, spec.w), Color.WHITE, true)
		edge.visible = false
	StaticDecorationBatch.build(self)

func point(x: float, z: float, lift: float = 0) -> Vector3:
	return terrain.point(x, z, lift)
