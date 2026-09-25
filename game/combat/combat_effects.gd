class_name CombatEffects
extends RefCounted
## Disposable floating feedback; never decides hits.

static func burst(parent: Node, at: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	parent.add_child(label)
	label.global_position = at + Vector3.UP * 1.4
	label.text = text
	label.font_size = 42
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.no_depth_test = true
	label.render_priority = 127
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y + 1.2, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

static func sparks(parent: Node, at: Vector3) -> void:
	burst(parent, at - Vector3.UP * 0.7, "CLINK!", Color("fff1a8"))
	for index in 10:
		var spark := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.085
		mesh.height = 0.36
		mesh.radial_segments = 4
		mesh.rings = 2
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("fff8cb") if index % 2 == 0 else Color("ff963f")
		mesh.material = material
		spark.mesh = mesh
		parent.add_child(spark)
		spark.global_position = at
		var angle := index * TAU / 10.0
		var direction := Vector3(cos(angle), sin(angle) * 0.7 + 0.3, sin(angle))
		spark.rotation = Vector3(angle, 0, -angle)
		var tween := spark.create_tween().set_parallel(true)
		tween.tween_property(spark, "global_position", at + direction * 1.1, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.42)
		tween.chain().tween_callback(spark.queue_free)

static func punch(parent: Node, at: Vector3) -> void:
	var fist := Sprite3D.new()
	fist.texture = preload("res://assets/combat/fist.svg")
	fist.pixel_size = 0.006
	fist.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(fist)
	fist.global_position = at
	var tween := fist.create_tween().set_parallel(true)
	tween.tween_property(fist, "scale", Vector3.ONE * 1.4, 0.18)
	tween.tween_property(fist, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(fist.queue_free)

static func damage_number(parent: Node, receiver: Damageable, amount: float) -> void:
	# Aggregate rapid liquid hits into one readable number beside this target.
	var cached: Variant = receiver.get_meta("damage_number") if receiver.has_meta("damage_number") else null
	var label: Label3D = cached if is_instance_valid(cached) else null
	if not is_instance_valid(label):
		label = Label3D.new()
		parent.add_child(label)
		label.font_size = 30
		label.pixel_size = 0.007
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 127
		label.set_meta("amount", 0.0)
		receiver.set_meta("damage_number", label)
	var old_tween: Tween = label.get_meta("fade") if label.has_meta("fade") else null
	if old_tween != null and old_tween.is_valid(): old_tween.kill()
	var total := float(label.get_meta("amount")) + amount
	label.set_meta("amount", total)
	label.text = "-%.1f" % total
	label.modulate = Color("fff5d6")
	var camera := receiver.get_viewport().get_camera_3d()
	var side := camera.global_basis.x if camera != null else Vector3.RIGHT
	label.global_position = receiver.global_position + Vector3.UP * 0.7 + side * 0.8
	var tween := label.create_tween().set_parallel(true)
	label.set_meta("fade", tween)
	tween.tween_property(label, "position:y", label.position.y + 0.4, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
