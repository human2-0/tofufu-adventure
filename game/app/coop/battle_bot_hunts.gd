class_name BattleBotHunts
extends RefCounted
## Nearby hunts compete with scavenging, while close player fights take priority.

static func command(slot: int, state: BattleMatch, original: Array, player_distance: float) -> Array:
	if state.mobs.is_empty(): return original
	var at := state.position_of(slot)
	if BattleRing.outside(at, state.time + 12, state.circle): return original
	var distance := 484.0
	var target := Vector3.INF
	for row: Array in state.mobs[0]:
		if row[9] != 0: continue
		var mob := Vector3(row[4][0], row[4][1], row[4][2])
		var d := at.distance_squared_to(mob)
		# Most hunts are far away. Reject them before recalculating their storm circle.
		if d >= distance or absf(mob.y - at.y) > 8: continue
		if BattleRing.outside(mob, state.time + 12, state.circle): continue
		if d < distance:
			distance = d
			target = mob
	if not target.is_finite() or (player_distance < 900 and distance > 36): return original
	if distance > 49 and not state.pack.is_empty() and not state.pack[slot][1].has([]): return original
	var direction := target - at
	var aim := Vector2(direction.x, direction.z).normalized()
	var ranged := int(state.rows[slot][10]) in [2, 7, 8, 11]
	var move := aim
	if ranged and distance < 100: move = -aim if distance < 36 else aim.orthogonal() * sin(state.time + slot)
	var flags := int(original[4]) & ~(1 | 2 | 512 | 16384 | 32768)
	if BattleBotSkill.firing(slot, state) and distance < (400 if ranged else 4.8): flags |= 1
	if ranged: flags |= 16384
	else: flags |= 32768
	if state.rows[slot][10] == 0 and distance < 4.8: flags |= 2
	var inaccurate := BattleBotSkill.aim(aim, slot, state)
	return [move.x, move.y, inaccurate.x, inaccurate.y, flags, direction.normalized().y, 0, clampf(sqrt(distance), 0.1, 160)]
