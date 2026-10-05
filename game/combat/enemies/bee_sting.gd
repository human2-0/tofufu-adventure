class_name BeeSting
extends Node3D
## One reusable swept projectile per bee; only its authority calls step().

signal struck(victim: Node3D, source: Vector3)
const SPEED: float = 16.0
const LIFETIME: float = 1.5
var active: bool = false
var velocity := Vector3.ZERO
var remaining: float = 0.0

func _ready() -> void:
	top_level = true
	var needle := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.095
	mesh.height = 0.55
	mesh.radial_segments = 6
	needle.mesh = mesh
	needle.rotation.x = -PI / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffbe38")
	material.emission_enabled = true
	material.emission = Color("ffb52b")
	material.emission_energy_multiplier = 0.8
	needle.material_override = material
	add_child(needle)
	visible = false

func launch(at: Vector3, direction: Vector3) -> void:
	global_position = at
	velocity = direction * SPEED
	remaining = LIFETIME
	active = true
	visible = true
	_face()

func step(delta: float, protected_area: Rect2, shooter: RID) -> void:
	if not active: return
	var destination := global_position + velocity * minf(delta, remaining)
	var source := global_position - velocity * (LIFETIME - remaining)
	remaining = maxf(0.0, remaining - delta)
	# Sweeping the safe rectangle also blocks a bolt crossing it in one large tick.
	if _crosses_protected(destination, protected_area):
		clear()
		return
	var query := PhysicsRayQueryParameters3D.create(global_position, destination, 3, [shooter])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		clear()
		if hit.collider is Node3D and not protected_area.has_point(Vector2(hit.position.x, hit.position.z)):
			struck.emit(hit.collider, source)
		return
	global_position = destination
	if remaining <= 0.0: clear()

func clear() -> void:
	active = false
	visible = false
	remaining = 0.0

func _crosses_protected(destination: Vector3, bounds: Rect2) -> bool:
	if not bounds.has_area(): return false
	var start := Vector2(global_position.x, global_position.z)
	var end := Vector2(destination.x, destination.z)
	if bounds.has_point(start) or bounds.has_point(end): return true
	var corners := [bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]
	for index in 4:
		if Geometry2D.segment_intersects_segment(start, end, corners[index], corners[(index + 1) % 4]) != null: return true
	return false

func capture() -> Array:
	var at := global_position if active else Vector3.ZERO
	var motion := velocity if active else Vector3.ZERO
	return [at.x, at.y, at.z, motion.x, motion.y, motion.z, remaining]

func apply(data: Array) -> void:
	global_position = Vector3(data[0], data[1], data[2])
	velocity = Vector3(data[3], data[4], data[5])
	remaining = data[6]
	active = remaining > 0.0
	visible = active
	_face()

func _face() -> void:
	if velocity.is_zero_approx(): return
	var up := Vector3.RIGHT if absf(velocity.normalized().dot(Vector3.UP)) > 0.98 else Vector3.UP
	look_at(global_position + velocity, up)
