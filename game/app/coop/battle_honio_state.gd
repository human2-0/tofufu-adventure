class_name BattleHonioState
extends RefCounted
## Battle-specific snapshots keep Honio out of Adventure world/save schemas.
static func capture(mob: HonioMeniono) -> Array:
	var m := mob.melee
	return BattleCombatWire.precision([m.phase, m.remaining, m.special_rest, m.aim.x, m.aim.z,
		m.facing.x, m.facing.z, m.sequence, m.skill, m.impact, m.bark, int(mob._returning), m.speech_time])

static func present(mob: HonioMeniono, data: Array) -> void:
	var m := mob.melee
	m.phase = int(data[0]) as HonioMelee.Phase
	m.remaining = float(data[1])
	m.special_rest = float(data[2])
	m.aim = Vector3(data[3], 0, data[4])
	m.facing = Vector3(data[5], 0, data[6])
	m.sequence = int(data[7])
	m.skill = int(data[8]) as HonioMelee.Skill
	m.impact = float(data[9])
	m.bark = int(data[10])
	mob._returning = data[11] == 1
	m.speech_time = float(data[12])

static func restore(mob: HonioMeniono, data: Array) -> void:
	present(mob, data)
	# Cancel unfinished contact attacks on host changes, retaining cooldown and sequence.
	mob.melee.cancel()
	mob._windup = 0
	mob.velocity.x = 0
	mob.velocity.z = 0
