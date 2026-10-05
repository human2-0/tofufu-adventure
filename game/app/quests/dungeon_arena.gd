class_name DungeonArena
extends RefCounted
## Places participating actors clear of the doorway before sealing the arena.

static func enter(dungeon: TofuDungeon) -> void:
	if dungeon.boss_members.is_empty():
		for actor: Node3D in dungeon._actors_inside():
			if DungeonCombatAccess.alive(dungeon, actor): dungeon.boss_members.append(DungeonMembership.key_for(dungeon, actor as Player))
	var index: int = 0
	for node: Node3D in dungeon._actors_inside():
		var actor := node as Player
		if actor == null: continue
		var at: Vector3 = TofuFactory.recovery_anchor(5) + Vector3(index * 1.35, 0, 0)
		dungeon._teleport_actor(actor, at)
		dungeon._recovery.seed(DungeonMembership.key_for(dungeon, actor), at, 5)
		index += 1
	dungeon.factory.seal_arena()
