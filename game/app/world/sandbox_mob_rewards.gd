class_name SandboxMobRewards
extends RefCounted
## App-owned kill rewards and loot; called only from authoritative defeat signals.

static func defeated(encounters: SandboxEncounters, at: Vector3, mob: TrainingMob) -> void:
	if encounters.magic_drop.is_valid(): encounters.magic_drop.call(at)
	encounters.mobs += 1
	var reward := encounters.ARMORED_SNAIL_EXPERIENCE if mob is ArmoredSnail else encounters.MOB_EXPERIENCE
	if mob is WildBee: reward = encounters.BEE_EXPERIENCE
	if mob is TofufuArcher: reward = TofufuArcher.EXPERIENCE
	if mob is BengalMonster:
		reward = BengalMonster.EXPERIENCE
		if encounters.bengal_drop.is_valid(): encounters.bengal_drop.call(at)
	encounters.experience += reward
	encounters.experience_changed.emit(encounters.experience)
	encounters.experience_awarded.emit(reward)
	encounters.mob_defeated.emit(at)
	if mob is TofufuArcher: encounters.angel_defeated.emit(at)
	if mob is ArmoredSnail: encounters.armored_snail_defeated.emit()
	encounters._drop(at, 3 if mob is WildBee else (4 if mob is ArmoredSnail else 2))
	var chance := float(encounters.loot_chance.call(encounters.SHELL_PIECE_DROP_CHANCE, at)) if encounters.loot_chance.is_valid() else encounters.SHELL_PIECE_DROP_CHANCE
	if mob is ArmoredSnail and encounters.shell_drop.is_valid() and float(encounters.shell_drop_roll.call()) < chance:
		for index in (2 if mob.shell_health <= 0.0 else 1):
			encounters.shell_drop.call("piece_of_shell", at + Vector3.RIGHT * index * 0.35)
	CombatEffects.burst(encounters, at, "+%d EXP" % reward, Color("b0e6cb"))
	encounters.progress_changed.emit(encounters.beans, encounters.mobs, encounters.props)

