class_name CloudDepositAccess
extends RefCounted
## Cloud access points reuse identity-owned Meadow deposits and transfer intents.

static func bay_for(realm: CloudRealm, actor: Node3D) -> int:
	if realm == null or actor == null or not actor.is_inside_tree(): return -1
	var selected := -1
	var best := 2.15
	for index in realm.deposit_sites.size():
		var site := realm.deposit_sites[index]
		var local := site.to_local(actor.global_position)
		if absf(local.y) > 1.5 or local.z < 0.65: continue
		var distance := Vector2(local.x, local.z - 1.0).length()
		if distance >= best: continue
		var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.7, site.to_global(Vector3(0, 0.7, 0.8)), 1)
		if not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		selected = index
		best = distance
	return selected
