class_name AngelFlameSphere
extends RefCounted
## A single spherical pulse; cover and target eligibility match projectile combat.

const RADIUS: float = 3.5

static func pulse(arrow: AngelArrow, at: Vector3, struck: Damageable) -> void:
	if not arrow.authoritative: return
	var seen: Array[Damageable] = [struck]
	for target in arrow.targets:
		if not is_instance_valid(target) or target in seen or target.current <= 0.0: continue
		seen.append(target)
		var offset := target.global_position - at
		if offset.length() > RADIUS: continue
		var excludes: Array[RID] = []
		if is_instance_valid(struck.body): excludes.append(struck.body.get_rid())
		var start := at + offset.normalized() * 0.04
		var ray := PhysicsRayQueryParameters3D.create(start, target.global_position, 1, excludes)
		var cover := arrow.get_world_3d().direct_space_state.intersect_ray(ray)
		if not cover.is_empty() and cover.collider != target.body: continue
		if target.receive_attack(arrow.body_damage, offset.normalized() * 4.0, Damageable.HitKind.SOY, target.global_position, arrow.bow.combat.owner_health):
			arrow.credit(target, target.global_position, arrow.body_damage, false)

static func spawn(parent: Node, at: Vector3) -> void:
	var sphere := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = RADIUS
	mesh.height = RADIUS * 2.0
	mesh.radial_segments = 40
	mesh.rings = 20
	sphere.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/combat/ranged/angel_flame.gdshader")
	material.set_shader_parameter("flames", preload("res://assets/weapons/angel_bow/flames.png"))
	sphere.material_override = material
	parent.add_child(sphere)
	sphere.global_position = at
	sphere.scale = Vector3.ONE * 0.1
	var tween := sphere.create_tween().set_parallel()
	tween.tween_property(sphere, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter("fade", value), 1.0, 0.0, 0.65)
	tween.chain().tween_callback(sphere.queue_free)
