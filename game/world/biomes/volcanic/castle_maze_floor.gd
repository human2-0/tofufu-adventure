class_name CastleMazeFloor
extends Node3D
## One 81-chamber maze deck, with distinct stonework and chamber landmarks.

var layout: CastleMazeLayout
var floor_index: int
var walls: Array[MeshInstance3D] = []
var slabs: Array[MeshInstance3D] = []
const COLORS: Array[Color] = [Color("6f5350"), Color("53516a"), Color("62664c")]

func _ready() -> void:
	name = "MazeFloor%d" % floor_index
	layout = CastleMazeLayout.new(floor_index)
	var color := COLORS[floor_index]
	slabs.append(CastleGeometry.solid(self, Vector3(0, -0.25, 0), Vector3(54, 0.5, 54), color.darkened(0.15)))
	for row in CastleMazeLayout.SIZE:
		for column in CastleMazeLayout.SIZE:
			var cell := Vector2i(column, row)
			var center := CastleMazeLayout.center(cell, 0)
			var mask := layout.passages[CastleMazeLayout.index(cell)]
			if mask & 1 == 0 and not (row == 0 and column == 4): _wall(center + Vector3(0, 3.8, -3), Vector3(6.6, 7.6, 0.6), color)
			if mask & 8 == 0: _wall(center + Vector3(-3, 3.8, 0), Vector3(0.6, 7.6, 6.6), color)
			if column == 8: _wall(center + Vector3(3, 3.8, 0), Vector3(0.6, 7.6, 6.6), color)
			if row == 8 and column != 4: _wall(center + Vector3(0, 3.8, 3), Vector3(6.6, 7.6, 0.6), color)
			_dress(cell, center, color)
	CastleGeometry.title(self, Vector3(0, 3.0, 27.35), ["I · EMBER CLOISTER", "II · OBSIDIAN ARCHIVE", "III · CROWN LABYRINTH"][floor_index])

func _wall(at: Vector3, size: Vector3, color: Color) -> void:
	var wall := CastleGeometry.solid(self, at, size, color)
	wall.set_meta("full_y", at.y)
	walls.append(wall)

func _dress(cell: Vector2i, center: Vector3, color: Color) -> void:
	var index := CastleMazeLayout.index(cell)
	if index % 7 == 0:
		MeadowGeometry.box(self, center + Vector3(0, 0.012, 0), Vector3(4.7, 0.02, 4.7), color.lightened(0.2))
	if index % 11 == 0:
		var monument := MeadowGeometry.box(self, center + Vector3(1.8, 0.45, 1.8), Vector3(0.7, 0.9, 0.7), Color("bc9865"))
		monument.rotation.y = PI * 0.25
	if index % 13 == 0:
		var flame := MeadowGeometry.box(self, center + Vector3(-1.8, 1.7, -1.8), Vector3(0.18, 0.45, 0.18), Color("ffbb67"))
		var material := MeadowGeometry.material(Color("ffb557"))
		material.emission_enabled = true
		material.emission = Color("ff842c")
		material.emission_energy_multiplier = 2.0
		flame.material_override = material

func present(cutaway: bool) -> void:
	for wall in walls:
		wall.scale.y = 0.14 if cutaway else 1.0
		wall.position.y = 0.532 if cutaway else float(wall.get_meta("full_y"))
