class_name DungeonCombatAccess
extends RefCounted
## Combat participants must be alive, in the room, and separated by no solid wall.

static func alive(dungeon: TofuDungeon, actor: Node3D) -> bool:
	if not dungeon.cooperative: return dungeon.game.health.current > 0.0
	for member: CoopActor in dungeon.party.values():
		if member.actor == actor: return not member.spectating and member.health.current > 0.0
	return false

static func visible(dungeon: TofuDungeon, source: Vector3, actor: Node3D) -> bool:
	if not is_instance_valid(actor): return false
	if dungeon.puzzle_enabled and TofuFactory.room_at(source) != TofuFactory.room_at(actor.global_position): return false
	var query := PhysicsRayQueryParameters3D.create(source + Vector3.UP * 0.8, actor.global_position + Vector3.UP * 0.8, 1)
	var hit: Dictionary = actor.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == actor
