class_name ArenaMobExclusion
extends RefCounted
## Maintains the reserved arena clearing after legacy checkpoints and knockback.

static func apply(encounters: SandboxEncounters) -> void:
	for mob in encounters.mob_nodes:
		var at := Vector2(mob.position.x, mob.position.z)
		var safe := FarmDuelArena.mob_safe_point(at)
		if safe == at: continue
		mob.position = encounters.ground_point.call(safe.x, safe.y, 0.1)
		mob._destination = mob._home
		mob.velocity = Vector3.ZERO
		mob._knockback = Vector3.ZERO
		mob._windup = 0.0
		mob._warning.hide()
		if mob is WildBee: mob.sting.clear()
