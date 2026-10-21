class_name BattleMatch
extends RefCounted
## Match-only resources and elimination. Adventure saves/progression never enter.

var rows: Array = []
var loot: Array = []
var combat: Array = []
var pack: Array = []
var chests: Array = []
var drops: Array = []
var mobs: Array = []
var time: float = 0.0
var winner: int = -2
var cooldowns: Array[float] = []
var reloads: Array[float] = []
var alive: int = 20
var options: Array = [19, BattleOptions.NORMAL]
var sequence: int = 0
var deployment: Dictionary = {}
var circle: Vector2 = BattleRing.CENTER
var stats: Array = []

func initialize(spawns: Array[Vector3], human_count: int, settings: Array = [19, 1]) -> void:
	rows.clear()
	deployment.clear()
	loot.clear()
	combat.clear()
	pack.clear()
	chests.clear()
	drops.clear()
	mobs.clear()
	cooldowns.clear()
	reloads.clear()
	time = 0
	winner = -2
	options = BattleOptions.canonical(settings)
	alive = BattleOptions.seats(options, human_count)
	circle = BattleRing.CENTER
	stats = BattleRoundStats.create(alive)
	for i in alive:
		var at := spawns[i]
		rows.append([at.x, at.y, at.z, 0.0, 0.0, 0.0, 0.0, 1.0, 100.0, 50.0, 2, 9, 0, 0, 0, 0, 1, int(i >= human_count), 2, 0.0, 0.0, 0.0, 1, 2])
		cooldowns.append(0.0)
		reloads.append(0.0)

func step(delta: float) -> void:
	if winner != -2: return
	time += delta
	for i in rows.size():
		cooldowns[i] = maxf(0, cooldowns[i] - delta)
		if rows[i][8] <= 0: continue
		stats[i][BattleRoundStats.SECONDS] = minf(900, float(stats[i][BattleRoundStats.SECONDS]) + delta)
		var quiet := float(stats[i][BattleRoundStats.QUIET])
		stats[i][BattleRoundStats.QUIET] = minf(8, quiet + delta)
		if quiet >= 8 and rows[i][9] < 50: rows[i][9] = minf(50, float(rows[i][9]) + delta * 5)
		if time > BattleRing.GRACE and BattleRing.outside(position_of(i), time, circle):
			hit(i, BattleRing.damage(time) * delta, -1, true)
		if position_of(i).y < -40: hit(i, 100, -1, true)
	BattleTeams.finish(self)

func hit(target: int, amount: float, attacker: int, storm: bool = false) -> void:
	if not is_finite(amount) or amount <= 0: return
	if winner != -2 or time < BattleRing.GRACE or rows[target][8] <= 0: return
	if not storm and BattleTeams.allies(options, target, attacker): return
	var actual := minf(amount, float(rows[target][8]) + (0 if storm else float(rows[target][9])))
	stats[target][BattleRoundStats.QUIET] = 0.0
	stats[target][BattleRoundStats.TAKEN] = minf(100000, float(stats[target][BattleRoundStats.TAKEN]) + actual)
	if attacker >= 0 and attacker != target:
		stats[attacker][BattleRoundStats.DAMAGE] = minf(100000, float(stats[attacker][BattleRoundStats.DAMAGE]) + actual)
	if not storm:
		var absorbed := minf(float(rows[target][9]), amount)
		rows[target][9] -= absorbed
		amount -= absorbed
	rows[target][8] = maxf(0, float(rows[target][8]) - amount)
	if rows[target][8] > 0: return
	alive -= 1
	BattleTeams.eliminated(self, target)
	if attacker >= 0 and attacker != target: rows[attacker][12] += 1
	if pack.is_empty() and loot.size() < 160 and rows[target][10] > 0:
		var at := position_of(target)
		loot.append([loot.size(), at.x, at.y, at.z, BattleGear.LOOT_WEAPONS.find(int(rows[target][10])), 1])

func position_of(slot: int) -> Vector3:
	return Vector3(rows[slot][0], rows[slot][1], rows[slot][2])

func use_loot(slot: int) -> void:
	if not pack.is_empty(): return
	if rows[slot][8] <= 0 or time < BattleRing.GRACE: return
	for item: Array in loot:
		if item[5] == 0 or position_of(slot).distance_squared_to(Vector3(item[1], item[2], item[3])) > 6.25: continue
		var weapon: int = BattleGear.LOOT_WEAPONS[int(item[4])]
		if weapon > 0:
			var column := 22 if weapon in BattleGear.MELEE else 23
			if int(rows[slot][column]) == weapon: continue
			var previous: int = rows[slot][column]
			rows[slot][column] = weapon
			rows[slot][10] = weapon
			if previous > 0 and loot.size() < 160:
				loot.append([loot.size(), item[1], item[2], item[3], BattleGear.LOOT_WEAPONS.find(previous), 1])
		else:
			match int(item[4]):
				2:
					if rows[slot][9] >= 100: continue
					rows[slot][9] = minf(100, float(rows[slot][9]) + 50)
				3:
					if rows[slot][16] >= 3: continue
					rows[slot][16] += 1
				4:
					if combat.is_empty(): continue
					var state := BattleCombatWire.unpack(combat[slot])
					if state.vitals.stamina >= 100: continue
					state.vitals.stamina = minf(100, float(state.vitals.stamina) + 35)
					combat[slot] = BattleCombatWire.pack(state)
		item[5] = 0
		return

func drop(slot: int) -> void:
	if not pack.is_empty(): return
	var weapon := int(rows[slot][10])
	if weapon == 0 or rows[slot][8] <= 0 or time < BattleRing.GRACE or loot.size() >= 160: return
	var at := position_of(slot)
	loot.append([loot.size(), at.x, at.y, at.z, BattleGear.LOOT_WEAPONS.find(weapon), 1])
	rows[slot][22 if weapon in BattleGear.MELEE else 23] = 0
	rows[slot][10] = 0

func heal(slot: int) -> void:
	if not pack.is_empty(): return
	if rows[slot][16] <= 0 or rows[slot][8] <= 0 or rows[slot][8] >= 100 or cooldowns[slot] > 0: return
	rows[slot][16] -= 1
	rows[slot][8] = minf(100, float(rows[slot][8]) + 40)
	cooldowns[slot] = 1.5

func capture(include_loot: bool = true) -> Dictionary:
	sequence += 1
	var packet := {"seq": sequence, "time": time, "winner": winner, "actors": rows.duplicate(true), "options": options.duplicate()}
	packet.circle = [circle.x, circle.y]
	packet.stats = BattleCombatWire.precision(stats)
	packet.mobs = mobs.duplicate(true)
	if not deployment.is_empty(): packet.deployment = deployment.duplicate(true)
	if not combat.is_empty(): packet.combat = combat.duplicate(true)
	if not pack.is_empty():
		packet.pack = pack.duplicate(true)
		packet.chests = chests.duplicate(true)
		packet.drops = drops.duplicate(true)
	if include_loot: packet.loot = loot.duplicate(true)
	return packet
