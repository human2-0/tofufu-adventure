class_name DungeonMembership
extends RefCounted
## Run membership survives boundary correction and uses stable co-op member keys.

static func key_for(dungeon: TofuDungeon, actor: Player) -> String:
	if not dungeon.cooperative: return "solo" if actor == dungeon.game.player else ""
	for key: String in dungeon.party:
		if dungeon.party[key].actor == actor: return key
	return ""

static func actor_id(dungeon: TofuDungeon, actor: Player) -> int:
	var key: String = key_for(dungeon, actor)
	return DungeonActorIdentity.get_id(dungeon, key)

static func contains(dungeon: TofuDungeon, actor: Player) -> bool:
	var key := key_for(dungeon, actor)
	return not key.is_empty() and key in dungeon.state.run_members

static func enter(dungeon: TofuDungeon, actor: Player) -> void:
	var key := key_for(dungeon, actor)
	if not key.is_empty() and key not in dungeon.state.run_members:
		actor_id(dungeon, actor)
		dungeon.state.run_members.append(key)
		dungeon._recovery.seed(key, TofuFactory.HALL_ARRIVAL, 0)
		dungeon.state.changed.emit()

static func exit(dungeon: TofuDungeon, actor: Player) -> void:
	var key := key_for(dungeon, actor)
	if key in dungeon.state.run_members:
		if dungeon.puzzle_enabled: dungeon.puzzle_runtime.release_actor(actor)
		dungeon.state.run_members.erase(key)
		dungeon._recovery.forget(key)
		dungeon.state.changed.emit()

static func checkpoint(dungeon: TofuDungeon) -> Vector3:
	if dungeon.puzzle_enabled and dungeon.puzzle.stage == TofuPuzzleContract.Stage.BOSS: return TofuFactory.recovery_anchor(5)
	if dungeon.state.stage <= 0: return TofuFactory.HALL_ARRIVAL
	return TofuFactory.CENTERS[clampi(dungeon.state.stage - 1, 0, 5)] + Vector3(0, 0.2, 4)

static func step_party_portals(dungeon: TofuDungeon, delta: float) -> void:
	for member: CoopActor in dungeon.party.values():
		var actor: Player = member.actor
		dungeon._connect_actor(actor)
		if not is_instance_valid(actor): continue
		var cooldown: float = maxf(0.0, float(dungeon._party_cooldowns.get(actor, 0.0)) - delta)
		dungeon._party_cooldowns[actor] = cooldown
		if cooldown > 0.0: continue
		if dungeon.actor_in_run(actor):
			if dungeon.factory.entrance_inside_reached(actor) or dungeon.state.completed and dungeon.factory.exit_reached(actor):
				exit(dungeon, actor)
				dungeon._teleport_actor(actor, TofuFactory.EAST_ENTRANCE + Vector3(-2.5, 0, 0))
				dungeon._party_cooldowns[actor] = 2.0
		elif dungeon.factory.entrance_reached(actor):
			if dungeon.puzzle_enabled and dungeon.puzzle.phase == TofuPuzzleContract.Phase.COMBAT: continue
			dungeon.factory.ensure_interior()
			dungeon.state.enter()
			enter(dungeon, actor)
			dungeon._teleport_actor(actor, TofuFactory.HALL_ARRIVAL)
			dungeon._party_cooldowns[actor] = 1.5
			if actor == dungeon.game.player: dungeon.game.hud.announce("Tofu Dungeon · Follow the factory recipe")
