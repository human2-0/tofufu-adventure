class_name MerchantLocations
extends RefCounted
## Both shops use the same proximity and occlusion checks on local and host actors.

static func nearest(world: Meadow, actor: Node3D) -> Node3D:
	var closest: Node3D
	var distance := 3.0
	for npc: Node3D in [world.weapon_merchant, world.cloud_realm.court.merchant]:
		var target := npc.global_position + Vector3(0, 0.6, 0.65)
		var current := actor.global_position.distance_to(target)
		if current > distance: continue
		var body := npc.get_node("ResidentBody") as StaticBody3D
		var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.6, target, 1, [body.get_rid()])
		if not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		closest = npc
		distance = current
	return closest

static func title(world: Meadow, npc: Node3D) -> String:
	return "Nimbus · Royal Outfitter" if npc == world.cloud_realm.court.merchant else "Grandpa Fufu · Gear Shop"

static func stock(world: Meadow, npc: Node3D) -> Array[String]:
	var ids: Array[String] = []
	if npc == world.cloud_realm.court.merchant: ids.append_array(CelestialItems.IDS)
	for id in WeaponTrade.BUYABLE_IDS:
		if id not in CelestialItems.IDS: ids.append(id)
	return ids
