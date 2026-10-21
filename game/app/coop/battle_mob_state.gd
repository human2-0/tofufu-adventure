class_name BattleMobState
extends RefCounted
## Shared adventure presentation records plus bounded recovery-only AI values.

static func capture(mob: TrainingMob, row: Array) -> void:
	row[4] = BattleCombatWire.precision(EncounterState.mob(mob))
	if row[9] != 0: row[4][7] = 900
	row[5] = snappedf(mob._rest, 0.001)
	row[6] = snappedf(mob._rush_cooldown, 0.001) if mob is ArmoredSnail else 0
	row[7] = snappedf(mob._defend_cooldown, 0.001) if mob is ArmoredSnail else 0
	row[8] = snappedf(mob._provoked, 0.001) if mob is WildBee else 0
	var d := mob._destination
	var k := mob._knockback
	row[12] = BattleCombatWire.precision([d.x, d.y, d.z, maxf(0, mob._timer), k.x, k.y, k.z, mob.target.paralysis])
	row[13] = str(mob._rng.state)

static func restore(mob: TrainingMob, row: Array) -> void:
	EncounterState.apply_mob(mob, row[4])
	mob._home = Vector3(row[1], row[2], row[3])
	var ai: Array = row[12]
	mob._destination = Vector3(ai[0], ai[1], ai[2])
	mob._timer = float(ai[3])
	mob._knockback = Vector3(ai[4], ai[5], ai[6])
	mob.target.paralysis = float(ai[7])
	mob._rng.state = int(row[13])
	mob._rest = maxf(0.75, float(row[5]))
	mob._windup = 0
	mob._warning.hide()
	mob.reaction.clear()
	if mob is ArmoredSnail:
		mob._cancel_rush()
		mob._defend = 0
		mob._rush_cooldown = maxf(0.75, float(row[6]))
		mob._defend_cooldown = float(row[7])
	if mob is WildBee:
		mob.sting.clear()
		mob._provoked = float(row[8])
	capture(mob, row)
