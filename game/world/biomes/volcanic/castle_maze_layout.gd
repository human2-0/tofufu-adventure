class_name CastleMazeLayout
extends RefCounted
## Seeded perfect mazes: every chamber reachable, many branches, long royal routes.

const SIZE: int = 9
const CELL: float = 6.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
var passages := PackedInt32Array()
var entrance: Vector2i
var exit_cell: Vector2i
var solution: Array[Vector2i] = []

func _init(floor_index: int) -> void:
	entrance = Vector2i(4, 8) if floor_index % 2 == 0 else Vector2i(4, 0)
	exit_cell = Vector2i(4, 0) if floor_index % 2 == 0 else Vector2i(4, 8)
	for attempt in 200:
		_generate(7841 + floor_index * 173 + attempt)
		solution = route(entrance, exit_cell)
		if solution.size() >= 45: break

func _generate(seed_value: int) -> void:
	passages.resize(SIZE * SIZE)
	passages.fill(0)
	var visited: Dictionary[Vector2i, bool] = {entrance: true}
	var stack: Array[Vector2i] = [entrance]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	while not stack.is_empty():
		var cell: Vector2i = stack.back()
		var choices: Array[int] = []
		for direction in 4:
			var next := cell + DIRECTIONS[direction]
			if valid(next) and not visited.has(next): choices.append(direction)
		if choices.is_empty():
			stack.pop_back()
			continue
		var direction := choices[rng.randi_range(0, choices.size() - 1)]
		var next := cell + DIRECTIONS[direction]
		passages[index(cell)] |= 1 << direction
		passages[index(next)] |= 1 << ((direction + 2) % 4)
		visited[next] = true
		stack.append(next)

func route(start: Vector2i, finish: Vector2i) -> Array[Vector2i]:
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary[Vector2i, Vector2i] = {start: start}
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell == finish: break
		for direction in 4:
			if passages[index(cell)] & (1 << direction) == 0: continue
			var next := cell + DIRECTIONS[direction]
			if previous.has(next): continue
			previous[next] = cell
			queue.append(next)
	var result: Array[Vector2i] = [finish]
	while result.back() != start: result.append(previous[result.back()])
	result.reverse()
	return result

func dead_ends() -> int:
	var total := 0
	for mask in passages:
		if mask in [1, 2, 4, 8]: total += 1
	return total

static func valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE

static func index(cell: Vector2i) -> int:
	return cell.y * SIZE + cell.x

static func center(cell: Vector2i, y: float) -> Vector3:
	return Vector3((cell.x - 4) * CELL, y, (cell.y - 4) * CELL)
