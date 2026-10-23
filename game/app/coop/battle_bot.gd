class_name BattleBot
extends RefCounted
## Ten-Hz steering can run on assigned peers; damage/collisions stay authoritative.

static func command(slot: int, match_state: BattleMatch) -> Array:
	var row: Array = match_state.rows[slot]
	var at := match_state.position_of(slot)
	var planar := Vector2(at.x, at.z)
	var goal := BattleRing.center(match_state.time + 12, match_state.circle)
	var distance: float = INF
	var target: int = -1
	for i in match_state.rows.size():
		if BattleTeams.allies(match_state.options, slot, i) or match_state.rows[i][8] <= 0: continue
		var d := at.distance_squared_to(match_state.position_of(i))
		if d > 10000 or absf(at.y - match_state.position_of(i).y) > 12: continue
		if d < distance:
			distance = d
			target = i
	var ranged := int(row[10]) in [2, 7, 8, 11]
	var flags: int = 32 | 4096
	if row[8] < 65: flags |= 64
	if ranged and row[11] == 0: flags |= 128
	var aim := Vector2.DOWN
	var pitch: float = 0
	var danger := BattleRing.outside(at, match_state.time + 12, match_state.circle)
	if target >= 0:
		var opponent := BattleBotSkill.perceived(match_state, target)
		pitch = (opponent - at).normalized().y
		aim = BattleBotSkill.aim((Vector2(opponent.x, opponent.z) - planar).normalized(), slot, match_state)
		if not danger:
			goal = Vector2(opponent.x, opponent.z)
			if ranged and distance < 90: goal = planar - aim * 4
			elif ranged and distance < 350: goal = planar + aim.orthogonal() * sin(match_state.time + slot) * 3
		var range_limit := BattleBotSkill.RANGE[int(match_state.options[1])]
		if BattleBotSkill.firing(slot, match_state):
			if (ranged and distance < range_limit * range_limit) or distance < 5: flags |= 1
		if ranged and distance < range_limit * range_limit: flags |= 512
		if distance < 4: flags |= 32768
		elif not ranged: flags |= 16384
		if row[10] == 0 and distance < 5: flags |= 2
	if row[10] == 0 and not danger:
		var closest: float = 2500
		for item: Array in match_state.loot:
			if item[5] == 0 or item[4] > 1: continue
			var where := Vector2(item[1], item[3])
			var d := planar.distance_squared_to(where)
			if d < closest:
				closest = d
				goal = where
	if not danger and distance > 900 and not match_state.pack.is_empty():
		var loot_goal := _loot_goal(slot, planar, match_state)
		if loot_goal.is_finite(): goal = loot_goal
	if not danger and target < 0 and BattleOptions.duos(match_state.options):
		var buddy := slot ^ 1
		if buddy < match_state.rows.size() and match_state.rows[buddy][8] > 0:
			var partner := match_state.position_of(buddy)
			if at.distance_squared_to(partner) > 900: goal = Vector2(partner.x, partner.z)
	var move := (goal - planar).normalized()
	# Periodic hops and lateral steering prevent simple cover from trapping CPUs.
	var beat := int(match_state.time * 10) + slot * 7
	var hop := beat % 120
	if hop < 8: flags |= 4
	if hop == 0: flags |= 8
	if beat % 47 == 0: flags |= 16
	if beat % 40 < 8: move = (move + move.orthogonal() * 0.7).normalized()
	return BattleBotHunts.command(slot, match_state, [move.x, move.y, aim.x, aim.y, flags, pitch, 0, clampf(sqrt(distance), 0.1, 160)], distance)

static func _loot_goal(slot: int, planar: Vector2, state: BattleMatch) -> Vector2:
	var pack: Array = state.pack[slot]
	var free: bool = pack[1].has([])
	var closest: float = 6400
	var goal := Vector2(INF, INF)
	if free:
		for chest: Array in state.chests:
			if chest[4] != 0: continue
			var where := Vector2(chest[1], chest[3])
			var distance := planar.distance_squared_to(where)
			if distance < closest:
				closest = distance
				goal = where
	for drop: Array in state.drops:
		if drop[5] <= 0: continue
		var where := Vector2(drop[1], drop[3])
		var distance := planar.distance_squared_to(where)
		if distance >= closest: continue
		var kind := int(drop[4])
		if not BattlePackBots.wants(pack, kind, -1, float(drop[6]), drop.size() == 8): continue
		var category: String = BattlePackWire.CATEGORIES[kind - 1]
		var useful := free
		if not free and category in ["support", "material"]:
			for stack: Array in pack[1]:
				if not stack.is_empty() and stack[0] == kind and stack[1] + drop[5] <= (10 if kind == 28 else 50): useful = true
		if not useful: continue
		if distance < closest:
			closest = distance
			goal = where
	return goal
