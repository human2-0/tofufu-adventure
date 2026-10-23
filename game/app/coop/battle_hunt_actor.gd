class_name BattleHuntActor
extends RefCounted
## Explicit finite Royale enemy catalog, independent from Adventure spawn tables.
static func build(game: BattleRoyaleGame, row: Array) -> TrainingMob:
	var mob: TrainingMob = [TrainingMob, ArmoredSnail, WildBee, HonioMeniono][int(row[0])].new()
	mob.position = Vector3(row[1], row[2], row[3])
	game.add_child(mob)
	BattleVisibility.limit(mob)
	mob.leash_radius = 38 if mob is HonioMeniono else 18
	mob.tuning = mob.tuning.duplicate()
	mob.tuning.dry_health = BattleMobWire.HEALTH[int(row[0])]
	mob.target.maximum = mob.tuning.dry_health
	if mob is WildBee: mob.ranged_enabled = false
	if mob is HonioMeniono:
		for fighter in game.combat.fighters: mob.survivors.append(fighter.health)
	mob.set_physics_process(false)
	mob.target.set_physics_process(false)
	return mob
