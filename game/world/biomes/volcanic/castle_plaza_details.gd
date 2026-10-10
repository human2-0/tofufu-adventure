class_name CastlePlazaDetails
extends RefCounted
## Low-contrast royal inlays, carpet edging and carved throne and spring surrounds.

static func build(parent: Node3D) -> void:
	var batch := CastleDecorationBatch.new()
	for side in [-1.0, 1.0]:
		batch.box("stone", Vector3(side * 26.5, 2.04, 0), Vector3(1.2, 0.16, 54))
		for x in [-15.0, 15.0]: batch.box("stone", Vector3(x, 2.04, side * 26.5), Vector3(24, 0.16, 1.2))
		batch.box("dark", Vector3(side * 24.5, 0.014, 0), Vector3(0.22, 0.018, 49))
		batch.box("dark", Vector3(0, 0.014, side * 24.5), Vector3(49, 0.018, 0.22))
		batch.box("bronze", Vector3(side * 2.15, 0.064, -6), Vector3(0.08, 0.018, 33.8))
	for z in [-22.7, 10.7]:
		batch.box("bronze", Vector3(0, 0.064, z), Vector3(4.3, 0.018, 0.1))
		for i in 20: batch.box("bronze", Vector3(-2.05 + i * 0.215, 0.064, z + signf(z + 6) * 0.16), Vector3(0.025, 0.02, 0.22))
	for i in 24:
		var angle := i * TAU / 24.0
		batch.box("dark", Vector3(sin(angle) * 12.4, 0.025, cos(angle) * 12.4), Vector3(0.11, 0.025, 2.1), angle)
	for radius in [9.5, 12.6]: _ring(parent, radius)
	_throne(batch)
	for x in [-12.0, 12.0]:
		for z in [-12.0, 12.0]: _brazier(batch, Vector3(x, 0, z))
	for x in [-18.0, 18.0]:
		for z in [-16.0, 16.0]: _spring(batch, Vector3(x, 0, z))
	batch.build(parent, "RoyalCraftwork")
	_cover(parent)

static func _cover(parent: Node3D) -> void:
	var trim := CastleDecorationBatch.new()
	for x in [-8.5, 8.5]:
		for z in [-7.5, 7.5]:
			CastleGeometry.solid(parent, Vector3(x, 1.2, z), Vector3(2.4, 2.4, 2.4), Color("493d48"))
			for y in [0.2, 2.3]: trim.box("bronze", Vector3(x, y, z), Vector3(2.5, 0.12, 2.5))
			trim.box("stone", Vector3(x, 2.46, z), Vector3(2.6, 0.12, 2.6))
	trim.build(parent, "ArenaCoverBindings")

static func _ring(parent: Node3D, radius: float) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.035
	mesh.outer_radius = radius + 0.035
	mesh.rings = 64
	mesh.ring_segments = 6
	mesh.material = CastleMaterials.metal(Color("8e7859"), 0.35)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	view.position.y = 0.032
	view.scale.y = 0.2
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(view)

static func _throne(batch: CastleDecorationBatch) -> void:
	batch.box("stone", Vector3(0, 0.1, 23), Vector3(6.2, 0.2, 4.2))
	batch.box("bronze", Vector3(0, 5.25, 22), Vector3(4.6, 0.3, 1.4))
	batch.box("cloth", Vector3(0, 1.0, 20.6), Vector3(3.7, 0.22, 1.5))
	for side in [-1.0, 1.0]:
		batch.box("bronze", Vector3(side * 1.87, 2.7, 22.6), Vector3(0.18, 4.8, 0.15))
		batch.box("iron", Vector3(side * 2.3, 3, 24.05), Vector3(0.48, 0.6, 0.16))
		for y in [0.3, 4.85]: batch.box("bronze", Vector3(side * 2.3, y, 23), Vector3(0.88, 0.22, 3.0))
	batch.crest(Vector3(0, 3.8, 21.36), PI, 1.4)

static func _brazier(batch: CastleDecorationBatch, at: Vector3) -> void:
	batch.box("stone", at + Vector3.UP * 0.12, Vector3(2.2, 0.24, 2.2))
	batch.box("bronze", at + Vector3.UP * 0.4, Vector3(1.9, 0.15, 1.9))
	for side in [-1.0, 1.0]:
		batch.box("bronze", at + Vector3(side * 0.92, 1.68, 0), Vector3(0.14, 0.22, 2))
		batch.box("bronze", at + Vector3(0, 1.68, side * 0.92), Vector3(2, 0.22, 0.14))
		for z in [-0.78, 0.78]: batch.box("iron", at + Vector3(side * 0.78, 1.15, z), Vector3(0.12, 1.9, 0.12))

static func _spring(batch: CastleDecorationBatch, at: Vector3) -> void:
	for side in [-1.0, 1.0]:
		for i in 10:
			batch.box("bronze", at + Vector3(side * 2.42, 0.315, -2.25 + i * 0.5), Vector3(0.34, 0.025, 0.06))
		batch.box("bronze", at + Vector3(0, 0.315, side * 2.42), Vector3(5.1, 0.025, 0.06))
