class_name BattleDeploymentState
extends RefCounted
## Value-only plant reservations, shared only by allies. Stage 0 chooses, 1 emerges.
const LIMIT: int = 96
const SELECTION_SECONDS: float = 30.0
const EMERGENCE_SECONDS: float = 3.0

static func create(sites: Array, count: int) -> Dictionary:
	var choices: Array = []
	var locked: Array = []
	for slot in count:
		choices.append(-1)
		locked.append(0)
	return {"sites": sites, "choices": choices, "locked": locked, "stage": 0, "remaining": SELECTION_SECONDS}

static func active(state: Dictionary) -> bool:
	return not state.is_empty() and int(state.stage) < 2

static func available(state: Dictionary, options: Array, slot: int, plant: int) -> bool:
	if plant < 0 or plant >= state.sites.size(): return false
	for other in state.choices.size():
		if int(state.choices[other]) == plant and not BattleTeams.allies(options, slot, other): return false
	return true

static func choose(state: Dictionary, options: Array, slot: int, plant: int, confirm: bool) -> bool:
	if slot < 0 or slot >= state.choices.size(): return false
	if int(state.stage) != 0 or int(state.locked[slot]) == 1 or not available(state, options, slot, plant): return false
	state.choices[slot] = plant
	state.locked[slot] = int(confirm)
	return true

static func complete(state: Dictionary, options: Array) -> void:
	for slot in state.choices.size():
		if int(state.choices[slot]) >= 0: continue
		# CPUs prefer their partner's reservation; enemies never share a plant.
		for other in state.choices.size():
			if BattleTeams.allies(options, slot, other) and int(state.choices[other]) >= 0:
				state.choices[slot] = int(state.choices[other])
				break
		if int(state.choices[slot]) >= 0: continue
		for offset in state.sites.size():
			var plant: int = (slot * 17 + offset) % state.sites.size()
			if available(state, options, slot, plant):
				state.choices[slot] = plant
				break
	state.locked.fill(1)
	state.stage = 1
	state.remaining = EMERGENCE_SECONDS

static func valid(value: Variant, count: int, options: Array) -> bool:
	if not value is Dictionary or value.size() != 5: return false
	if not BattleProtocol.integer(value.get("stage"), 0, 2) or not BattleProtocol.number(value.get("remaining"), 0, SELECTION_SECONDS): return false
	if int(value.stage) == 1 and float(value.remaining) > EMERGENCE_SECONDS: return false
	if int(value.stage) == 2 and float(value.remaining) != 0: return false
	var sites: Variant = value.get("sites")
	if not sites is Array or sites.size() < count or sites.size() > LIMIT: return false
	for site: Variant in sites:
		if not site is Array or site.size() != 3: return false
		for coordinate in site:
			if not BattleProtocol.number(coordinate, -450, 450): return false
	for field in ["choices", "locked"]:
		if not value.get(field) is Array or value[field].size() != count: return false
	for slot in count:
		if not BattleProtocol.integer(value.choices[slot], -1, sites.size() - 1) or not BattleProtocol.integer(value.locked[slot], 0, 1): return false
		if int(value.stage) > 0 and int(value.locked[slot]) != 1: return false
		var choice := int(value.choices[slot])
		if (int(value.stage) > 0 or int(value.locked[slot]) == 1) and choice < 0: return false
	var owners: Dictionary = {}
	for slot in count:
		var choice := int(value.choices[slot])
		if choice < 0: continue
		var team := BattleTeams.team(options, slot)
		if owners.has(choice) and int(owners[choice]) != team: return false
		owners[choice] = team
	return true
