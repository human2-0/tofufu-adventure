class_name CastleExteriorDetails
extends RefCounted
## Ashlar plinths, slit windows, bronze roofs and crowned textile standards.

static func build(parent: Node3D) -> void:
	var batch := CastleDecorationBatch.new()
	for y in [0.6, 7.8, 15.8, 23.8]:
		for side in [-1.0, 1.0]:
			batch.box("stone", Vector3(side * 27.55, y, 0), Vector3(0.9, 0.45, 54))
			for x in [-15.0, 15.0]: batch.box("stone", Vector3(x, y, side * 27.55), Vector3(24, 0.45, 0.9))
	for side in [-1.0, 1.0]:
		for z in [-18.0, -6.0, 6.0, 18.0]:
			for y in [4.0, 12.0, 20.0]:
				_window(batch, Vector3(side * 27.34, y, z), side * PI * 0.5)
		for x in [-12.0, 0.0, 12.0]:
			for y in [12.0, 20.0]: _window(batch, Vector3(x, y, side * 27.34), 0 if side > 0 else PI)
		for x in [-18.0, 18.0]: _banner(batch, Vector3(x, 15, side * 27.75), 0 if side > 0 else PI)
	for x in [-27.5, 27.5]:
		for z in [-27.5, 27.5]: _tower(batch, Vector3(x, 0, z))
	_entrance(batch)
	batch.build(parent, "FortressStonework")

static func _window(batch: CastleDecorationBatch, at: Vector3, yaw: float) -> void:
	_piece(batch, "iron", at, Vector3.ZERO, Vector3(1.55, 2.9, 0.12), yaw)
	_piece(batch, "glass", at, Vector3(0, 0, 0.08), Vector3(1.15, 2.45, 0.05), yaw)
	for side in [-1.0, 1.0]:
		_piece(batch, "stone", at, Vector3(side * 0.88, 0, 0.08), Vector3(0.3, 3.3, 0.3), yaw)
		_piece(batch, "stone", at, Vector3(0, side * 1.58, 0.12), Vector3(2.1, 0.3, 0.4), yaw)
	for x in [-0.4, 0.0, 0.4]: _piece(batch, "iron", at, Vector3(x, 0, 0.16), Vector3(0.055, 2.5, 0.055), yaw)
	for y in [-0.7, 0.7]: _piece(batch, "iron", at, Vector3(0, y, 0.16), Vector3(1.15, 0.055, 0.055), yaw)

static func _banner(batch: CastleDecorationBatch, at: Vector3, yaw: float) -> void:
	_piece(batch, "bronze", at, Vector3(0, 4.15, 0), Vector3(4.1, 0.16, 0.22), yaw)
	for side in [-1.0, 1.0]:
		_piece(batch, "bronze", at, Vector3(side * 1.63, 0, 0.08), Vector3(0.1, 7.8, 0.04), yaw)
	_piece(batch, "bronze", at, Vector3(0, -3.8, 0.08), Vector3(3.3, 0.12, 0.04), yaw)
	batch.crest(at + Vector3(0, 0.3, 0.12).rotated(Vector3.UP, yaw), yaw, 1.3)

static func _tower(batch: CastleDecorationBatch, at: Vector3) -> void:
	for y in [0.3, 1.0, 7.8, 15.8, 25.8]:
		batch.box("stone", at + Vector3.UP * y, Vector3(7.65, 0.45, 7.65))
	for corner in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		for i in 12:
			batch.box("stone", at + Vector3(corner.x * 3.55, 1.8 + i * 2.0, corner.y * 3.55), Vector3(0.6, 0.6, 0.6))
	for side in [-1.0, 1.0]:
		for y in [5.0, 13.0, 21.0]: _window(batch, at + Vector3(0, y, side * 3.56), 0 if side > 0 else PI)
	for i in 8:
		var angle := i * TAU / 8.0
		var bottom := at + Vector3(sin(angle) * 4.7, 27, cos(angle) * 4.7)
		var top := at + Vector3.UP * 35.0
		var length := bottom.distance_to(top)
		var basis := Basis.looking_at((top - bottom).normalized(), Vector3.UP)
		batch.oriented("bronze", (top + bottom) * 0.5, Vector3(0.07, 0.07, length), basis)
	batch.box("bronze", at + Vector3.UP * 35.4, Vector3(0.25, 1, 0.25))

static func _entrance(batch: CastleDecorationBatch) -> void:
	for side in [-1.0, 1.0]:
		batch.box("stone", Vector3(side * 3.6, 3.25, 28.0), Vector3(0.8, 6.5, 1.1))
		batch.box("bronze", Vector3(side * 3.6, 6.5, 28.0), Vector3(1.05, 0.25, 1.2))
	for i in 13:
		var angle := i * PI / 12.0
		var at := Vector3(cos(angle) * 3.6, 6.5 + sin(angle) * 3.6, 28.0)
		batch.oriented("stone", at, Vector3(0.95, 0.85, 1.1), Basis(Vector3.BACK, angle - PI * 0.5))
	batch.crest(Vector3(0, 11.4, 28.15), 0, 1.2)

static func _piece(batch: CastleDecorationBatch, kind: String, at: Vector3, offset: Vector3, size: Vector3, yaw: float) -> void:
	batch.box(kind, at + offset.rotated(Vector3.UP, yaw), size, yaw)
