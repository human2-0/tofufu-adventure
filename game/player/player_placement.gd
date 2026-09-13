class_name PlayerPlacement
extends RefCounted
## Collision-aware teleport placement; ordinary movement still uses the motor.

static func relocate(actor: CharacterBody3D, collider: CollisionShape3D, desired: Vector3, peers: Array[CharacterBody3D]) -> bool:
	var space := actor.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collider.shape
	query.collision_mask = 3
	query.exclude = [actor.get_rid()]
	for index in 97:
		var candidate := desired
		if index > 0:
			var ring := 1 + (index - 1) / 8
			var angle := (index - 1) % 8 * TAU / 8.0
			candidate += Vector3(cos(angle), 0, sin(angle)) * ring * 1.1
			var floor_query := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 2, candidate + Vector3.DOWN * 5, 1)
			var floor_hit := space.intersect_ray(floor_query)
			if floor_hit.is_empty(): continue
			candidate.y = floor_hit.position.y + 0.05
		var transform := actor.global_transform
		transform.origin = candidate
		query.transform = transform * collider.transform
		if overlaps_actors(actor, collider.shape, query.transform, peers): continue
		if not space.intersect_shape(query, 1).is_empty(): continue
		actor.global_position = candidate
		actor.velocity = Vector3.ZERO
		return true
	return false

static func overlaps_actors(actor: CharacterBody3D, capsule: CapsuleShape3D, at: Transform3D, peers: Array[CharacterBody3D]) -> bool:
	# Physics query transforms can lag other teleports in the same tick.
	# Explicit live handles cover same-tick arrivals without a global registry.
	for peer in peers:
		if not is_instance_valid(peer) or peer == actor or peer.collision_layer & 2 == 0: continue
		for owner: int in peer.get_shape_owners():
			if peer.is_shape_owner_disabled(owner): continue
			var shape := peer.shape_owner_get_shape(owner, 0) as CapsuleShape3D
			if shape == null: continue
			var center := (peer.global_transform * peer.shape_owner_get_transform(owner)).origin
			var offset := at.origin - center
			var gap := maxf(0.0, absf(offset.y) - (capsule.height + shape.height) * 0.5 + capsule.radius + shape.radius)
			if Vector2(offset.x, offset.z).length_squared() + gap * gap < pow(capsule.radius + shape.radius + 0.02, 2):
				return true
	return false
