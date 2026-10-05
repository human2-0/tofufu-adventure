class_name SnailShellEffects
extends RefCounted
## Short-lived contact sparks and shell fragments; no gameplay outcomes.

static func impact(parent: Node, at: Vector3, broken: bool) -> void:
	if not broken:
		CombatEffects.sparks(parent, at, false)
		return
	for index in 12:
		var shard := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(0.18, 0.12, 0.24)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("b28a5c") if index % 2 == 0 else Color("806249")
		material.roughness = 1.0
		mesh.material = material
		shard.mesh = mesh
		parent.add_child(shard)
		shard.global_position = at
		var angle := index * TAU / 12.0
		var outward := Vector3(cos(angle), 0, sin(angle)) * (0.7 + (index % 3) * 0.25)
		var tween := shard.create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "global_position", at + outward + Vector3.UP * 0.6, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", Vector3(angle, angle * 2.0, angle), 0.6)
		tween.chain().tween_property(shard, "global_position", at + outward * 1.6 + Vector3.DOWN * 0.5, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(shard, "scale", Vector3.ZERO, 0.4)
		tween.chain().tween_callback(shard.queue_free)
