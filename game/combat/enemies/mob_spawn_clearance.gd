class_name MobSpawnClearance
extends RefCounted
## Respawn overlap query shared by the existing snail lifecycle.

static func clear(mob: TrainingMob) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = mob._collider.shape
	query.collision_mask = 3
	query.exclude = [mob.get_rid()]
	var spawn_transform := mob.transform
	spawn_transform.origin = mob._home
	query.transform = mob.get_parent_node_3d().global_transform * spawn_transform * mob._collider.transform
	if mob.spawn_clearance.is_valid() and not mob.spawn_clearance.call(query.shape, query.transform): return false
	return mob.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
