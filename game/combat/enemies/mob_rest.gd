class_name MobRest
extends RefCounted
## Reuses an unchanged permanent terrain contact only while a body is stationary.

var _support: StaticBody3D
var _shape: CollisionShape3D
var _geometry: Shape3D
var _support_transform: Transform3D
var _at: Vector3

func can_rest(body: CharacterBody3D, direction: Vector3, push: Vector3) -> bool:
	if not direction.is_zero_approx() or not push.is_zero_approx(): return false
	if not body.is_on_floor() or absf(body.velocity.y) > 0.05: return false
	if not is_instance_valid(_support) or not is_instance_valid(_shape): return false
	if _shape.disabled or _shape.shape != _geometry or (_support.collision_layer & body.collision_mask) == 0: return false
	return body.global_position.is_equal_approx(_at) and _shape.global_transform.is_equal_approx(_support_transform)

func remember(body: CharacterBody3D) -> void:
	_support = null
	_shape = null
	_geometry = null
	if not body.is_on_floor(): return
	for index in body.get_slide_collision_count():
		var contact := body.get_slide_collision(index)
		if contact.get_normal().dot(body.up_direction) < cos(body.floor_max_angle): continue
		var floor_body := contact.get_collider() as StaticBody3D
		if floor_body == null or not floor_body.get_meta("permanent_terrain", false): continue
		var floor_shape := contact.get_collider_shape() as CollisionShape3D
		if floor_shape == null: continue
		_support = floor_body
		_shape = floor_shape
		_geometry = _shape.shape
		_support_transform = _shape.global_transform
		_at = body.global_position
		return
