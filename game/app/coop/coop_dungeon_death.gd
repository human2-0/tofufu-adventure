class_name CoopDungeonDeath
extends RefCounted
## Releases run props and parks a defeated member until encounter resolution.

static func defer(member: CoopActor) -> bool:
	if member.world_items == null: return false
	var dungeon: TofuDungeon = member.world_items.game.factory_dungeon
	if dungeon == null or not dungeon.actor_in_run(member.actor): return false
	dungeon.puzzle_runtime.release_actor(member.actor)
	if not dungeon.puzzle_enabled or dungeon.puzzle.phase != TofuPuzzleContract.Phase.COMBAT: return false
	member.spectating = true
	member.actor.set_physics_process(false)
	member.actor.relocate(DungeonMembership.checkpoint(dungeon))
	member.actor.velocity = Vector3.ZERO
	member.combat.reset()
	if member.hud != null: member.hud.announce("Spectating until the encounter ends")
	return true

static func respawn(member: CoopActor) -> void:
	if member.duel_defeated.is_valid(): return
	member.spectating = false
	member.actor.set_physics_process(member.authority)
	member.respawn_count += 1
	var dungeon: TofuDungeon = member.world_items.game.factory_dungeon if member.world_items != null else null
	member.actor.relocate(DungeonMembership.checkpoint(dungeon) if dungeon != null and dungeon.actor_in_run(member.actor) else Vector3(0, 0.2, 2))
	member.actor.velocity = Vector3.ZERO
	member.actor.motor.is_dashing = false
	member.actor.motor.is_super_dashing = false
	member.actor.motor.cancel_jump()
	member.actor.visuals.jump_animation.reset()
	member.health.restore()
	member.combat.reset()
	if member.hud != null: member.hud.announce("Back at the nursery / Fresh health. Your friends are waiting!")
