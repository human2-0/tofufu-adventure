class_name MapExploration
extends RefCounted
## Personal visited cells, independent of UI, actors and transport.

const BOUNDS := Rect2(-142, -369, 848, 960)
const GRID := Vector2i(424, 480)
const BYTE_COUNT: int = (424 * 480 + 7) / 8
const RADIUS: float = 10.0
var _bits := PackedByteArray()
var _pixels := PackedByteArray()
var revision: int = 0

func _init() -> void:
	_bits.resize(BYTE_COUNT)
	_bits.fill(0)
	_pixels.resize(GRID.x * GRID.y)
	_pixels.fill(0)

func reveal(point: Vector2) -> bool:
	if not BOUNDS.has_point(point): return false
	var center := _cell(point)
	var changed := false
	for y in range(maxi(0, center.y - 6), mini(GRID.y, center.y + 7)):
		for x in range(maxi(0, center.x - 6), mini(GRID.x, center.x + 7)):
			var at := BOUNDS.position + (Vector2(x, y) + Vector2.ONE * 0.5) / Vector2(GRID) * BOUNDS.size
			if at.distance_to(point) > RADIUS: continue
			var index := y * GRID.x + x
			var mask := 1 << (index % 8)
			if _bits[index / 8] & mask: continue
			_bits[index / 8] |= mask
			_pixels[index] = 255
			changed = true
	if changed: revision += 1
	return changed

func visited(point: Vector2) -> bool:
	if not BOUNDS.has_point(point): return false
	var cell := _cell(point)
	return _seen(cell.y * GRID.x + cell.x)

func _cell(point: Vector2) -> Vector2i:
	return Vector2i((point - BOUNDS.position) / BOUNDS.size * Vector2(GRID))

func _seen(index: int) -> bool:
	return (_bits[index / 8] & (1 << (index % 8))) != 0

func mask_image() -> Image:
	# Movement only updates newly visited pixels; native upload copies this cached mask.
	return Image.create_from_data(GRID.x, GRID.y, false, Image.FORMAT_L8, _pixels)

func capture() -> String:
	return Marshalls.raw_to_base64(_bits)

func restore(value: Variant) -> void:
	_bits.fill(0)
	if value is String and value.length() in [10120, 20468, 33920] and RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$").search(value) != null:
		var decoded := Marshalls.base64_to_raw(value)
		if Marshalls.raw_to_base64(decoded) == value:
			if decoded.size() == BYTE_COUNT: _bits = decoded
			elif decoded.size() == 7589: _restore_legacy(decoded, Vector2i(171, 355), Vector2(342, 709))
			elif decoded.size() == 15350: _restore_legacy(decoded, Vector2i(307, 400), Vector2(614, 800))
	for index in _pixels.size(): _pixels[index] = 255 if _seen(index) else 0
	revision += 1

func _restore_legacy(decoded: PackedByteArray, old_grid: Vector2i, old_size: Vector2) -> void:
	# Both older atlases retain discoveries at their original world cell centers.
	for index in old_grid.x * old_grid.y:
		if decoded[index / 8] & (1 << (index % 8)) == 0: continue
		var point := BOUNDS.position + (Vector2(index % old_grid.x, index / old_grid.x) + Vector2.ONE * 0.5) * old_size / Vector2(old_grid)
		var cell := _cell(point)
		var new_index := cell.y * GRID.x + cell.x
		_bits[new_index / 8] |= 1 << (new_index % 8)
