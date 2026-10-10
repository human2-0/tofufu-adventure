class_name CastleMazeDetails
extends RefCounted
## Stone caps track cutaways, while flush inlays and low props stay on their deck.

static func build(parent: Node3D, walls: Array[MeshInstance3D], deck: int) -> Node3D:
	var caps := CastleDecorationBatch.new()
	var base := CastleDecorationBatch.new()
	for wall in walls:
		var size: Vector3 = (wall.mesh as BoxMesh).size
		var at := Vector3(wall.position.x, 0, wall.position.z)
		caps.box("stone", at, Vector3(size.x + 0.14, 0.16, size.z + 0.14))
		base.box("dark", at + Vector3.UP * 0.22, Vector3(size.x + 0.1, 0.44, size.z + 0.1))
		if size.x > size.z:
			for x in [-2.7, 2.7]: caps.box("bronze", at + Vector3(x, 0.085, 0), Vector3(0.13, 0.025, size.z + 0.15))
		else:
			for z in [-2.7, 2.7]: caps.box("bronze", at + Vector3(0, 0.085, z), Vector3(size.x + 0.15, 0.025, 0.13))
	for row in CastleMazeLayout.SIZE:
		for column in CastleMazeLayout.SIZE:
			var cell := Vector2i(column, row)
			var at := CastleMazeLayout.center(cell, 0)
			var index := CastleMazeLayout.index(cell)
			if index % 7 == 0: _inlay(base, at)
			if index % 11 == 0: _relic(base, at + Vector3(1.8, 0, 1.8), deck)
			if index % 13 == 0: _torch(base, at + Vector3(-1.8, 0, -1.8))
	base.build(parent, "CloisterCarvings")
	var result := caps.build(parent, "WallCoping")
	result.position.y = 7.6
	return result

static func _inlay(batch: CastleDecorationBatch, at: Vector3) -> void:
	for side in [-1.0, 1.0]:
		batch.box("bronze", at + Vector3(side * 2.18, 0.028, 0), Vector3(0.07, 0.018, 4.4))
		batch.box("bronze", at + Vector3(0, 0.028, side * 2.18), Vector3(4.4, 0.018, 0.07))
	batch.box("dark", at + Vector3.UP * 0.025, Vector3(0.7, 0.025, 0.7), PI * 0.25)

static func _relic(batch: CastleDecorationBatch, at: Vector3, deck: int) -> void:
	batch.box("dark", at + Vector3.UP * 0.1, Vector3(1.2, 0.2, 1.2))
	batch.box("stone", at + Vector3.UP * 0.4, Vector3(0.8, 0.4, 0.8), PI * 0.25)
	batch.box("bronze", at + Vector3.UP * 0.65, Vector3(1.05, 0.1, 1.05))
	if deck == 1:
		for i in 3:
			batch.box("cloth", at + Vector3(0, 0.77 + i * 0.15, 0), Vector3(0.64, 0.13, 0.85), i * 0.18)
	else: batch.crest(at + Vector3(0, 1.05, 0), 0, 0.45)

static func _torch(batch: CastleDecorationBatch, at: Vector3) -> void:
	batch.box("dark", at + Vector3.UP * 0.1, Vector3(0.65, 0.2, 0.65))
	batch.box("iron", at + Vector3.UP * 0.8, Vector3(0.13, 1.45, 0.13))
	batch.box("bronze", at + Vector3.UP * 1.45, Vector3(0.48, 0.12, 0.48))
	for side in [-1.0, 1.0]:
		batch.box("iron", at + Vector3(side * 0.22, 1.62, 0), Vector3(0.07, 0.35, 0.45))
