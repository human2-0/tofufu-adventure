class_name FarmDuelArena
extends Node3D
## Village duel pads and the expanded, cover-filled arena near Gigalopolis.

const PAD_POINTS: Array[Vector2] = [Vector2(40, 4), Vector2(42.4, 4)]
const ARENA_CENTER := Vector2(70, 33)
const SPAWN_OFFSETS: Array[Vector2] = [Vector2(-15, 0), Vector2(15, 0)]
const ARENA_HALF_SIZE := Vector2(21, 17)
const WALL_HEIGHT: float = 3.2
const WALL_THICKNESS: float = 0.5
const FIGHTER_INSET: float = 1.0
const AUDIENCE_ROWS: int = 4
const AUDIENCE_STEP_HEIGHT: float = 0.7
const AUDIENCE_ROW_SPACING: float = 1.0
const AUDIENCE_ROW_DEPTH: float = 0.9

var _ground_point: Callable

func build(ground_point: Callable) -> void:
	_ground_point = ground_point
	_build_pads()
	_build_battlefield()

func pad_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for point in PAD_POINTS:
		result.append(_point(point))
	return result

func pad_exit_position(index: int) -> Vector3:
	var offset := Vector2(-1.4, -1.2) if index == 0 else Vector2(1.4, -1.2)
	var point := PAD_POINTS[clampi(index, 0, PAD_POINTS.size() - 1)] + offset
	return _point(point) + Vector3.UP * 0.12

func spawn_positions() -> Array[Vector3]:
	var result: Array[Vector3] = []
	var floor_y := _point(ARENA_CENTER).y
	for offset in SPAWN_OFFSETS:
		result.append(Vector3(ARENA_CENTER.x + offset.x, floor_y, ARENA_CENTER.y + offset.y))
	return result

func pad_for(at: Vector3) -> int:
	var pads := pad_positions()
	for index in pads.size():
		if Vector2(at.x - pads[index].x, at.z - pads[index].z).length() <= 1.05:
			return index
	return -1

func contains_arena(at: Vector3) -> bool:
	return absf(at.x - ARENA_CENTER.x) <= ARENA_HALF_SIZE.x - FIGHTER_INSET and absf(at.z - ARENA_CENTER.y) <= ARENA_HALF_SIZE.y - FIGHTER_INSET

func return_position(index: int) -> Vector3:
	var spawns := spawn_positions()
	return spawns[clampi(index, 0, spawns.size() - 1)] + Vector3.UP * 0.12

func _build_pads() -> void:
	for index in PAD_POINTS.size():
		var at := _point(PAD_POINTS[index])
		var color := Color("79c5b0") if index == 0 else Color("e3b16d")
		MeadowGeometry.box(self, at + Vector3.UP * 0.12, Vector3(1.9, 0.24, 1.9), Color("493e3d"), true)
		MeadowGeometry.box(self, at + Vector3.UP * 0.255, Vector3(1.6, 0.06, 1.6), color)
		MeadowGeometry.box(self, at + Vector3.UP * 0.31, Vector3(0.26, 0.045, 0.26), Color("fff0c2"))
	var sign_at := _point(Vector2(41.2, 6.0))
	MeadowGeometry.signpost(self, sign_at, "DUEL GATE · TWO FUFUS")
	var note := Label3D.new()
	note.double_sided = false
	note.text = "STAND ON A TILE WITH A FRIEND"
	note.position = _point(Vector2(41.2, 1.8)) + Vector3.UP * 1.25
	note.font_size = 24
	note.pixel_size = 0.02
	note.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	note.modulate = Color("343b34")
	note.no_depth_test = false
	note.render_priority = 127
	add_child(note)

func _build_battlefield() -> void:
	var center := _point(ARENA_CENTER)
	MeadowGeometry.box(self, center + Vector3.DOWN * 0.08, Vector3(ARENA_HALF_SIZE.x * 2, 0.16, ARENA_HALF_SIZE.y * 2), Color("bca47b"), true)
	var wall := Color("80634d")
	var half_x := ARENA_HALF_SIZE.x - WALL_THICKNESS * 0.5
	var half_z := ARENA_HALF_SIZE.y - WALL_THICKNESS * 0.5
	for side in [-1.0, 1.0]:
		MeadowGeometry.box(self, center + Vector3(0, WALL_HEIGHT * 0.5, side * half_z), Vector3(ARENA_HALF_SIZE.x * 2, WALL_HEIGHT, WALL_THICKNESS), wall, true)
		MeadowGeometry.box(self, center + Vector3(side * half_x, WALL_HEIGHT * 0.5, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, ARENA_HALF_SIZE.y * 2), wall, true)
	_build_cover(center)
	_build_audience(center)
	var sign := Label3D.new()
	sign.double_sided = false
	sign.text = "FIRST TO 10"
	sign.position = center + Vector3.UP * (WALL_HEIGHT + 1.0)
	sign.font_size = 32
	sign.pixel_size = 0.025
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sign.modulate = Color("343b34")
	sign.no_depth_test = false
	sign.render_priority = 127
	add_child(sign)

func _build_cover(center: Vector3) -> void:
	var full_cover := Color("9d7658")
	var low_cover := Color("c1996c")
	# Each spawn starts behind a full-height crate; a broken central wall hides the opponent until a flank is taken.
	for side in [-1.0, 1.0]:
		_box(center, Vector3(side * 11.3, 1.9, 0), Vector3(2.2, 3.8, 6.0), full_cover)
	for z in [-5.8, 0.0, 5.8]:
		_box(center, Vector3(0, 2.25, z), Vector3(3.4, 4.5, 5.8), full_cover)
	# Extra crates make corner cover and short routes along the arena walls.
	for x in [-17.0, 17.0]:
		for z in [-11.0, 11.0]:
			_box(center, Vector3(x, 1.55, z), Vector3(2.8, 3.1, 3.8), full_cover)
	for x in [-7.0, 7.0]:
		for z in [-10.0, 10.0]:
			_box(center, Vector3(x, 0.75, z), Vector3(3.0, 1.5, 2.8), low_cover)
	for side in [-1.0, 1.0]:
		_box(center, Vector3(side * 17.5, 0.95, 0), Vector3(1.8, 1.9, 4.2), low_cover)

func _build_audience(center: Vector3) -> void:
	var audience := Node3D.new()
	audience.name = "Audience"
	add_child(audience)
	var long_run := ARENA_HALF_SIZE.x * 2 - 2.0
	var short_run := ARENA_HALF_SIZE.y * 2 - 2.0
	for row in AUDIENCE_ROWS:
		var rise := row * AUDIENCE_STEP_HEIGHT
		var offset := ARENA_HALF_SIZE.y + WALL_THICKNESS * 0.5 + 1.5 + row * AUDIENCE_ROW_SPACING
		for side in [-1.0, 1.0]:
			var north_south := center + Vector3(0, rise + AUDIENCE_STEP_HEIGHT * 0.5, side * offset)
			var east_west := center + Vector3(side * (ARENA_HALF_SIZE.x + WALL_THICKNESS * 0.5 + 1.5 + row * AUDIENCE_ROW_SPACING), rise + AUDIENCE_STEP_HEIGHT * 0.5, 0)
			_seat_row(audience, north_south, Vector3(long_run, AUDIENCE_STEP_HEIGHT, AUDIENCE_ROW_DEPTH))
			_seat_row(audience, east_west, Vector3(AUDIENCE_ROW_DEPTH, AUDIENCE_STEP_HEIGHT, short_run))

func _seat_row(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var color := Color("77634d") if int(at.y / AUDIENCE_STEP_HEIGHT) % 2 == 0 else Color("927557")
	MeadowGeometry.box(parent, at, size, color, true)
	MeadowGeometry.box(parent, at + Vector3.UP * (size.y * 0.5 + 0.06), Vector3(size.x, 0.12, size.z), Color("d3ae79"))

func _box(center: Vector3, offset: Vector3, size: Vector3, color: Color) -> void:
	MeadowGeometry.box(self, center + offset, size, color, true)

func _point(point: Vector2) -> Vector3:
	var result: Vector3 = _ground_point.call(point.x, point.y)
	return result
