class_name CastleTreasureLayout
extends RefCounted
## Four remote branch ends per deck; identical locations for every seeded castle.

static func cells(layout: CastleMazeLayout) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for row in CastleMazeLayout.SIZE:
		for column in CastleMazeLayout.SIZE:
			var cell := Vector2i(column, row)
			if layout.passages[CastleMazeLayout.index(cell)] in [1, 2, 4, 8] and cell not in layout.solution:
				candidates.append(cell)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var depth_a := _depth(layout, a)
		var depth_b := _depth(layout, b)
		return depth_a > depth_b if depth_a != depth_b else CastleMazeLayout.index(a) < CastleMazeLayout.index(b))
	var result: Array[Vector2i] = []
	for cell in candidates:
		if result.size() == 4: break
		result.append(cell)
	return result

static func _depth(layout: CastleMazeLayout, cell: Vector2i) -> int:
	var path := layout.route(cell, layout.entrance)
	for i in path.size():
		if path[i] in layout.solution: return i * 100 + path.size()
	return 0

static func build(parent: Node3D, layout: CastleMazeLayout) -> Array[CastleTreasureChest]:
	var result: Array[CastleTreasureChest] = []
	for cell in cells(layout):
		var chest := CastleTreasureChest.new()
		var mask := layout.passages[CastleMazeLayout.index(cell)]
		var facing := Vector3.BACK
		for i in 4:
			if mask & (1 << i): facing = Vector3(CastleMazeLayout.DIRECTIONS[i].x, 0, CastleMazeLayout.DIRECTIONS[i].y)
		chest.position = CastleMazeLayout.center(cell, 0) - facing * 1.7
		chest.rotation.y = atan2(facing.x, facing.z)
		parent.add_child(chest)
		result.append(chest)
	return result
