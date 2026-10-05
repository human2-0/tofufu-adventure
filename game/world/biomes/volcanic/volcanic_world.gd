class_name VolcanicWorld
extends Node3D
## Separate eastern continent: ocean channel, volcanic beaches and royal maze castle.

var castle: LavaCastle
var atmosphere: VolcanicAtmosphere
var ocean: VolcanicOcean

func _ready() -> void:
	name = "EmbercrownContinent"
	var grid := VolcanicGroundGrid.new()
	VolcanicTerrain.build(self, grid)
	ocean = VolcanicOcean.new()
	ocean.build(grid)
	add_child(ocean)
	VolcanicLava.build(self, grid)
	VolcanicRoutes.build(self)
	VolcanicProps.build(self)
	VolcanicLandmarks.build(self)
	castle = LavaCastle.new()
	add_child(castle)
	atmosphere = VolcanicAtmosphere.new()
	add_child(atmosphere)

func point(x: float, z: float, lift: float = 0.0) -> Vector3:
	return VolcanicTerrain.point(Vector2(x, z), lift)

func is_water(at: Vector3) -> bool:
	return VolcanicTerrain.contains(Vector2(at.x, at.z)) and at.y < VolcanicTerrain.WATER_LEVEL and point(at.x, at.z).y < VolcanicTerrain.WATER_LEVEL
