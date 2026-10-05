class_name VolcanicGroundGrid
extends RefCounted
## Cache each two-metre terrain sample once before reusing it across six triangles.

const STRIDE: int = int(VolcanicTerrain.BOUNDS.size.x / 2) + 1
const ROWS: int = int(VolcanicTerrain.BOUNDS.size.y / 2) + 1
var heights := PackedFloat32Array()
var colors := PackedColorArray()

func _init() -> void:
	heights.resize(STRIDE * ROWS)
	colors.resize(heights.size())
	for row in ROWS:
		for column in STRIDE:
			var at := VolcanicTerrain.BOUNDS.position + Vector2(column, row) * 2
			var index := row * STRIDE + column
			heights[index] = VolcanicTerrain.height_at(at.x, at.y)
			colors[index] = VolcanicTerrain.color_at(at, heights[index]).srgb_to_linear()

func index(at: Vector2) -> int:
	return int((at.y - VolcanicTerrain.BOUNDS.position.y) / 2) * STRIDE + int((at.x - VolcanicTerrain.BOUNDS.position.x) / 2)

func point(at: Vector2, lift: float = 0.0) -> Vector3:
	# Barycentric sampling follows the exact diagonal used by collision triangles.
	var cell := ((at - VolcanicTerrain.BOUNDS.position) / 2.0).floor()
	var origin := VolcanicTerrain.BOUNDS.position + cell * 2.0
	var weight := (at - origin) / 2.0
	var h00 := heights[index(origin)]
	var h10 := heights[index(origin + Vector2(2, 0))]
	var h01 := heights[index(origin + Vector2(0, 2))]
	var h11 := heights[index(origin + Vector2(2, 2))]
	var height := h00 + (h10 - h00) * weight.x + (h01 - h00) * weight.y
	if weight.x + weight.y > 1.0:
		height = h11 + (h01 - h11) * (1 - weight.x) + (h10 - h11) * (1 - weight.y)
	return Vector3(at.x, height + lift, at.y)
