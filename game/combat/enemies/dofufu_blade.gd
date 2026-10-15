class_name DofufuBlade
extends Node3D
## Bounded returning fan blade with swept world collisions and real guard reflection.

var shooter: CharacterBody3D
var victim: Damageable
var boss_health: Damageable
var hurt: Callable
var velocity := Vector3.ZERO
var elapsed: float = 0.0
var reflected: bool = false
var amount: float = 22.0

func _ready() -> void:
	top_level = true
	var view := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.5, 0.12, 0.9)
	view.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("84f9d1")
	material.emission_enabled = true
	material.emission = Color("45c9a0")
	view.material_override = material
	add_child(view)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(shooter) or boss_health.current <= 0.0:
		queue_free()
		return
	elapsed += delta
	if elapsed >= 2.4:
		queue_free()
		return
	if elapsed > 0.7 and not reflected:
		var home := shooter.global_position + Vector3.UP * 0.8 - global_position
		if home.length() < 0.6:
			queue_free()
			return
		velocity = velocity.lerp(home.normalized() * 19.0, minf(1.0, delta * 7.0))
	var exclude: Array[RID] = []
	exclude.append(victim.body.get_rid() if reflected else shooter.get_rid())
	var destination := global_position + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, destination, 3, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if not reflected and hit.collider == victim.body:
			var normal := victim.reflection_normal(velocity, hit.position, true, amount)
			if not normal.is_zero_approx():
				reflected = true
				velocity = velocity.bounce(normal).normalized() * 22.0
				global_position = hit.position + velocity.normalized() * 0.25
				return
			hurt.call(amount, shooter.global_position, Vector3.ZERO)
		elif reflected and hit.collider == shooter:
			boss_health.damage(amount * 2.0, Vector3.ZERO, Damageable.HitKind.SOY, hit.position)
		queue_free()
		return
	global_position = destination
	rotation.y += delta * 15.0
