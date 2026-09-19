class_name ExplorationProtocol
extends RefCounted
## Version-2 co-op input and actor schema. Host identity comes from the transport.

const INPUT_FLAGS: Array[String] = ["jump_held", "jump_pressed", "dash_pressed", "attack_held", "guard_held", "punch_held", "drop_pressed", "pickup_pressed", "camp_pressed", "time_pressed", "cancel_actions"]

static func valid_input(data: Dictionary) -> bool:
	if not sequence(data.get("sequence")) or not sequence(data.get("ack")): return false
	for field in ["move", "aim", "dash"]:
		if not vector(data.get(field), 2, 1.001): return false
		var value: Array = data[field]
		if Vector2(value[0], value[1]).length_squared() > 1.01: return false
	for field in INPUT_FLAGS:
		if not data.get(field) is bool: return false
	if data.has("aim_point") and not vector(data.aim_point, 3, 500): return false
	return sequence(data.get("weapon_slot")) and data.weapon_slot <= 4

static func valid_snapshot(data: Dictionary, members: Array) -> bool:
	if not sequence(data.get("sequence")) or not data.get("actors") is Dictionary: return false
	if data.actors.size() > 4 or data.actors.is_empty(): return false
	for key: Variant in data.actors:
		if key not in members or not data.actors[key] is Dictionary or not actor(data.actors[key]): return false
	if data.has("world") and (not data.world is Dictionary or not WorldProtocol.valid(data.world)): return false
	return data.get("opening") is Dictionary and WorldProtocol.opening(data.opening)

static func actor(state: Dictionary) -> bool:
	if not vector(state.get("position"), 3, 500) or not vector(state.get("velocity"), 3, 200): return false
	if not vector(state.get("aim"), 2, 1.001): return false
	if state.has("facing_locked") and not state.facing_locked is bool: return false
	for field in ["grounded", "dashing"]:
		if not state.get(field) is bool: return false
	for field in ["charge", "cooldown", "health", "invulnerability"]:
		if not number(state.get(field), 100) or state[field] < 0: return false
	if state.charge > 1: return false
	if state.has("clearance") and not number(state.clearance, 100): return false
	for field in ["respawns", "blocks", "input_ack"]:
		if state.has(field) and not sequence(state[field]): return false
	if state.has("hits"):
		if not state.hits is Array or state.hits.size() != 3: return false
		for count in state.hits:
			if not sequence(count): return false
	if state.has("progression") and not progression(state.progression): return false
	return state.get("combat") is Dictionary and combat(state.combat)

static func combat(data: Dictionary) -> bool:
	if data.has("recoil") and (not number(data.recoil, 1) or data.recoil < 0): return false
	for field in ["gun", "ads", "jet", "jet_ads", "jet_firing"]:
		if data.has(field) and not data[field] is bool: return false
	if data.get("gun", false) and (data.get("selected", false) or data.get("guard", false) or data.get("active", false)): return false
	if data.get("jet", false) and (data.get("gun", false) or data.get("selected", false) or data.get("guard", false) or data.get("active", false)): return false
	if data.get("jet_firing", false) and not data.get("jet", false): return false
	if data.has("milk") and (not number(data.milk, 100) or data.milk < 0): return false
	if data.has("jet_sequence") and not sequence(data.jet_sequence): return false
	if data.has("jet_origin") and not vector(data.jet_origin, 3, 500): return false
	if data.has("jet_velocity") and not vector(data.jet_velocity, 3, 30): return false
	if data.has("shot") and not sequence(data.shot): return false
	if data.has("shot_origin") and not vector(data.shot_origin, 3, 500): return false
	if data.has("shot_velocity") and not vector(data.shot_velocity, 3, 60): return false
	for field in ["owned", "selected", "guard", "active"]:
		if not data.get(field) is bool: return false
	for field in ["aim", "facing"]:
		if not vector(data.get(field), 2, 1.001): return false
	for field in ["charge", "strength", "elapsed", "punch", "cooldown"]:
		if not number(data.get(field), 10) or data[field] < 0: return false
	if data.charge > 1 or data.strength > 1: return false
	return vector(data.get("drop"), 3, 500)

static func sequence(value: Variant) -> bool:
	return number(value, 2147483647) and value >= 0 and float(value) == floorf(value)

static func number(value: Variant, bound: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(value) <= bound

static func vector(value: Variant, count: int, bound: float) -> bool:
	if not value is Array or value.size() != count: return false
	for component: Variant in value:
		if not number(component, bound): return false
	return true

static func key(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value:
		if character not in "0123456789abcdef": return false
	return true

static func progression(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 3 or value.get("version") != 1: return false
	var xp: Variant = value.get("experience")
	if not _progress_counter(xp): return false
	var practice: Variant = value.get("practice")
	if not practice is Dictionary or practice.size() not in [5, 6]: return false
	for field in ["fist", "sword", "magic", "attack_speed", "defence"]:
		if not _progress_counter(practice.get(field)): return false
	if practice.size() == 6 and not _progress_counter(practice.get("shooting")): return false
	return true

static func _progress_counter(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 100000000 and float(value) == floorf(value)
