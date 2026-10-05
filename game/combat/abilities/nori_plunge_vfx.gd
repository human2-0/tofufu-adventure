class_name NoriPlungeVFX
extends RefCounted
## Cosmetic mint shock rings, seaweed shards and a vertical flash. No hit decisions.

static func launch(parent: Node, at: Vector3) -> void:
	_ring(parent, at + Vector3.UP * 0.08, 0.8, 0.3, Color("64c7ac"))

static func impact(parent: Node, at: Vector3, radius: float) -> void:
	_ink_wave(parent, at, radius)
	_ring(parent, at + Vector3.UP * 0.06, radius, 0.48, Color("99ffdc"))
	_ring(parent, at + Vector3.UP * 0.1, radius * 0.75, 0.65, Color("2b866d"))
	for i in 18:
		var angle := TAU * i / 18.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var shard := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.09, 0.32, 0.07)
		shard.mesh = mesh
		shard.material_override = _material(Color("b3ffe2") if i % 3 == 0 else Color("184f40"))
		parent.add_child(shard)
		shard.global_position = at + Vector3.UP * 0.1
		var tween := shard.create_tween().set_parallel()
		tween.tween_property(shard, "global_position", at + direction * radius * 0.85 + Vector3.UP * (0.3 + (i % 3) * 0.3), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", Vector3(angle, angle * 2, angle), 0.5)
		tween.tween_property(shard, "scale", Vector3.ZERO, 0.3).set_delay(0.25)
		tween.chain().tween_callback(shard.queue_free)
	var flash := MeshInstance3D.new()
	var beam := CylinderMesh.new()
	beam.top_radius = 0.02
	beam.bottom_radius = 0.2
	beam.height = 2.8
	flash.mesh = beam
	var material := _material(Color("ddfff1"))
	flash.material_override = material
	parent.add_child(flash)
	flash.global_position = at + Vector3.UP * 1.4
	var tween := flash.create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector3(0.1, 1.2, 0.1), 0.25)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.25)
	tween.chain().tween_callback(flash.queue_free)

static func _ring(parent: Node, at: Vector3, radius: float, duration: float, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.92
	mesh.outer_radius = 1.0
	mesh.rings = 48
	mesh.ring_segments = 8
	ring.mesh = mesh
	var material := _material(color)
	ring.material_override = material
	parent.add_child(ring)
	ring.global_position = at
	ring.scale = Vector3(0.15, 0.12, 0.15)
	var tween := ring.create_tween().set_parallel()
	tween.tween_property(ring, "scale", Vector3(radius, 0.08, radius), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, duration)
	tween.chain().tween_callback(ring.queue_free)

static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	return material

static func _ink_wave(parent: Node, at: Vector3, radius: float) -> void:
	var wave := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * 2.0
	wave.mesh = plane
	var material := _material(Color.WHITE)
	material.albedo_texture = preload("res://assets/weapons/nori/plunge_ring.png")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wave.material_override = material
	parent.add_child(wave)
	wave.global_position = at + Vector3.UP * 0.045
	wave.scale = Vector3.ONE * 0.2
	var tween := wave.create_tween().set_parallel()
	tween.tween_property(wave, "scale", Vector3.ONE * radius, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(wave, "rotation:y", 0.35, 0.6)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.5).set_delay(0.12)
	tween.chain().tween_callback(wave.queue_free)
