class_name DungeonSpectators
extends RefCounted
## Co-op encounter deaths defer revival until clearance or a full wipe.

static func step(dungeon: TofuDungeon) -> void:
	var inside: int = 0
	var down: int = 0
	for member: CoopActor in dungeon.party.values():
		if not dungeon.actor_in_run(member.actor): continue
		inside += 1
		if member.spectating:
			down += 1
			if dungeon.puzzle.phase != TofuPuzzleContract.Phase.COMBAT: member.respawn()
	if inside > 0 and down == inside and dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT:
		dungeon.puzzle_flow.reset_encounter(dungeon)
		for member: CoopActor in dungeon.party.values():
			if dungeon.actor_in_run(member.actor) and member.spectating: member.respawn()
		restart_boss_party(dungeon)

static func restart_boss_party(dungeon: TofuDungeon) -> void:
	if dungeon.puzzle.stage != TofuPuzzleContract.Stage.BOSS: return
	dungeon.boss_members.clear()
	for member: CoopActor in dungeon.party.values():
		if not dungeon.actor_in_run(member.actor) and member.health.current > 0.0 and dungeon.factory.entrance_reached(member.actor):
			DungeonMembership.enter(dungeon, member.actor)
	DungeonArena.enter(dungeon)
