class_name Podburst
extends RefCounted
## Authority-only wind cone; cooldown persists across equipment swaps.
const PUSH_SPEED: float = 18.0
var cooldown: float = 0.0
var sequence: int = 0

func fire(combat: PlayerCombat, aim: Vector2) -> void:
	if cooldown > 0.0 or not combat.vitals.spend(VitalRules.SPECIAL_COST): return
	cooldown = 3.0
	sequence += 1
	combat.strike(aim, 0.0)
	combat.special_attack = true
	combat.rules.cooldown = 0.5
	var forward := Vector3(aim.x, 0, aim.y).normalized()
	for target in combat.targets:
		if not is_instance_valid(target) or target == combat.owner_health: continue
		var offset := target.global_position - combat.actor.global_position
		var planar := Vector3(offset.x, 0, offset.z)
		if absf(offset.y) > 1.5 or planar.length() > 3.6 or planar.normalized().dot(forward) < 0.55: continue
		if not combat._unobstructed(combat.actor.global_position, target): continue
		if target.damage(8.0 * combat.sword_damage_multiplier, forward * PUSH_SPEED, Damageable.HitKind.MELEE):
			target.pushed.emit(forward * PUSH_SPEED)
			combat.vitals.confirmed_hit(false)
			combat._hit_targets.append(target)
			combat.struck.emit(0.0, 1)
			if target.trains_weapons and not combat._trained:
				combat._trained = true
				combat.weapon_trained.emit("sword")
			CombatEffects.burst(combat, target.global_position, "PODBURST!", Color("d7ffa0"))
	visual(combat, aim)

static func visual(combat: PlayerCombat, aim: Vector2) -> void:
	var fan := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.72, 1.0, 0.55, 0.65)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for i in 24:
		var a := -0.98 + i * 1.96 / 24.0
		var b := -0.98 + (i + 1) * 1.96 / 24.0
		for v in [Vector3(sin(a), 0, cos(a)), Vector3(sin(b), 0, cos(b)) * 0.82, Vector3(sin(b), 0, cos(b)), Vector3(sin(a), 0, cos(a)), Vector3(sin(a), 0, cos(a)) * 0.82, Vector3(sin(b), 0, cos(b)) * 0.82]:
			mesh.surface_add_vertex(v)
	mesh.surface_end()
	fan.mesh = mesh
	combat.add_child(fan)
	fan.global_position = combat.actor.global_position + Vector3.UP * 0.65
	fan.rotation.y = atan2(aim.x, aim.y)
	fan.scale = Vector3.ONE * 0.6
	var tween := fan.create_tween().set_parallel()
	tween.tween_property(fan, "scale", Vector3.ONE * 3.6, 0.32)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.4)
	tween.chain().tween_callback(fan.queue_free)
