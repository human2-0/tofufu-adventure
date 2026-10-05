class_name TerrainGrid
extends RefCounted
## Samples each terrain vertex once; mesh triangles reuse heights and palette colours.

var _bounds: Rect2i
var _stride: int
var _heights := PackedFloat32Array()
var _colors := PackedColorArray()

func _init(bounds: Rect2i, sample: Callable, seed: int) -> void:
	_bounds = bounds
	_stride = bounds.size.x + 1
	_heights.resize(_stride * (bounds.size.y + 1))
	_colors.resize(_heights.size())
	for row in bounds.size.y + 1:
		for column in _stride:
			var x := bounds.position.x + column
			var z := bounds.position.y + row
			var index := row * _stride + column
			_heights[index] = float(sample.call(float(x), float(z)))
			_colors[index] = BiomePalette.color_at(Vector2(x, z), _heights[index], seed)

func height(x: float, z: float) -> float:
	return _heights[(int(z) - _bounds.position.y) * _stride + int(x) - _bounds.position.x]

func color(x: float, z: float) -> Color:
	return _colors[(int(z) - _bounds.position.y) * _stride + int(x) - _bounds.position.x]

func interpolated_height(at: Vector2) -> float:
	var x := clampf(at.x, _bounds.position.x, _bounds.end.x - 0.001)
	var z := clampf(at.y, _bounds.position.y, _bounds.end.y - 0.001)
	var left := floorf(x)
	var top := floorf(z)
	return lerpf(lerpf(height(left, top), height(left + 1, top), x - left), lerpf(height(left, top + 1), height(left + 1, top + 1), x - left), z - top)
