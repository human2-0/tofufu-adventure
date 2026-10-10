class_name ExplorationProtocol
extends RefCounted
## Version-2 co-op input and actor schema. Host identity comes from the transport.

const INPUT_FLAGS: Array[String] = ["run_held", "face_aim", "jump_held", "jump_pressed", "dash_pressed", "dash_held", "attack_held", "guard_held", "punch_held", "drop_pressed", "pickup_pressed", "camp_pressed", "time_pressed", "cancel_actions", "use_healing_1", "use_healing_2", "use_healing_3", "use_healing_4"]

static func valid_input(data: Dictionary) -> bool:
	if not sequence(data.get("sequence")) or not sequence(data.get("ack")): return false
	for field in ["move", "aim", "dash"]:
		if not vector(data.get(field), 2, 1.001): return false
		var value: Array = data[field]
		if Vector2(value[0], value[1]).length_squared() > 1.01: return false
	for field in INPUT_FLAGS:
		if not data.get(field, false if field == "run_held" else null) is bool: return false
	if data.get("castle_action", -1) != -1 and (not sequence(data.castle_action) or data.castle_action > 24): return false
	if not sequence(data.get("castle_revision", 0)): return false
	if data.has("pickup_id") and data.pickup_id != -1 and not sequence(data.pickup_id): return false
	if data.has("aim_point") and not vector(data.aim_point, 3, 1000): return false
	return sequence(data.get("weapon_slot")) and data.weapon_slot <= 2

static func valid_snapshot(data: Dictionary, members: Array) -> bool:
	if not sequence(data.get("sequence")) or not data.get("actors") is Dictionary: return false
	if data.actors.size() > 4 or data.actors.is_empty(): return false
	for key: Variant in data.actors:
		if key not in members or not data.actors[key] is Dictionary or not actor(data.actors[key]): return false
	if data.has("world") and (not data.world is Dictionary or not WorldProtocol.valid(data.world)): return false
	if data.has("duel") and not DuelProtocol.valid(data.duel, members): return false
	return data.get("opening") is Dictionary and WorldProtocol.opening(data.opening)

static func actor(state: Dictionary) -> bool:
	if state.has("impact") and not impact(state.impact): return false
	if state.has("parrot_rest") and (not state.parrot_rest is Array or (not state.parrot_rest.is_empty() and not vector(state.parrot_rest, 3, 1000))): return false
	if state.has("endurance") and not endurance(state.endurance): return false
	if state.has("transport") and not state.transport is bool: return false
	if state.has("quests") and not GrandmaQuestProtocol.valid(state.quests): return false
	if state.has("active_slot") and (not sequence(state.active_slot) or state.active_slot < 1 or state.active_slot > 2): return false
	if not vector(state.get("position"), 3, 1000) or not vector(state.get("velocity"), 3, 200): return false
	if not vector(state.get("aim"), 2, 1.001): return false
	if state.has("facing_locked") and not state.facing_locked is bool: return false
	for field in ["grounded", "dashing"]:
		if not state.get(field) is bool: return false
	if state.has("super_dashing") and not state.super_dashing is bool: return false
	for field in ["charge", "cooldown", "invulnerability"]:
		if not number(state.get(field), 100) or state[field] < 0: return false
	if state.has("progression") and not progression(state.progression): return false
	var level := _character_level(state.get("progression", {}))
	if not number(state.get("health"), 100.0 * pow(1.05, level - 1)) or state.health < 0: return false
	if state.charge > 1: return false
	if state.has("clearance") and not number(state.clearance, 100): return false
	for field in ["respawns", "blocks", "input_ack"]:
		if state.has(field) and not sequence(state[field]): return false
	if state.has("hits"):
		if not state.hits is Array or state.hits.size() not in [3, 4]: return false
		for count in state.hits:
			if not sequence(count): return false
	if state.has("progression") and not progression(state.progression): return false
	return state.get("combat") is Dictionary and combat(state.combat)

static func combat(data: Dictionary) -> bool:
	if not sequence(data.get("celestial", 0)) or data.get("celestial", 0) > 3: return false
	if data.get("celestial", 0) == 1 and (not data.get("selected", false) or data.get("nori", false) or data.get("pod", false)): return false
	if data.get("celestial", 0) == 2 and not data.get("staff", false): return false
	if data.get("celestial", 0) == 3 and not data.get("gun", false): return false
	if not number(data.get("hit_pause", 0.0), 0.075) or data.get("hit_pause", 0.0) < 0: return false
	if not sequence(data.get("style", 0)) or data.get("style", 0) > 6: return false
	if not sequence(data.get("combo", 0)) or data.get("combo", 0) > 5: return false
	if not sequence(data.get("chain", 0)) or data.get("chain", 0) > 3: return false
	if not number(data.get("combo_window", 0.0), 1.15) or data.get("combo_window", 0.0) < 0: return false
	if data.has("vitals") and not vitals(data.vitals): return false
	for field in ["gun_owned", "sotjet_owned", "staff_owned", "world_drops"]:
		if data.has(field) and not data[field] is bool: return false
	if data.get("gun", false) and not data.get("gun_owned", true): return false
	if data.get("jet", false) and not data.get("sotjet_owned", true): return false
	if not number(data.get("pod_cooldown", 0.0), 3.0) or data.get("pod_cooldown", 0.0) < 0: return false
	if not number(data.get("plunge_recovery", 0.0), 0.22) or data.get("plunge_recovery", 0.0) < 0: return false
	if not sequence(data.get("plunge_sequence", 0)): return false
	if not number(data.get("plunge_cooldown", 0.0), 2.0) or data.get("plunge_cooldown", 0.0) < 0: return false
	if not vector(data.get("plunge_at", [0,0,0]), 3, 1000): return false
	if data.get("nori", false) and (not data.get("selected", false) or data.get("pod", false)): return false
	if data.get("plunging", false) and (not data.get("nori", false) or not data.get("active", false)): return false
	if not sequence(data.get("podburst", 0)): return false
	if data.get("pod", false) and not data.get("selected", false): return false
	if data.get("staff", false) and not data.get("staff_owned", false): return false
	if data.has("recoil") and (not number(data.recoil, 1) or data.recoil < 0): return false
	for field in ["gun", "ads", "jet", "jet_ads", "jet_firing", "staff", "pod", "nori", "plunging"]:
		if data.has(field) and not data[field] is bool: return false
	if data.get("gun", false) and (data.get("selected", false) or data.get("guard", false) or data.get("active", false)): return false
	if data.get("jet", false) and (data.get("gun", false) or data.get("selected", false) or data.get("guard", false) or data.get("active", false)): return false
	if data.get("staff", false) and (data.get("gun", false) or data.get("jet", false) or data.get("selected", false) or data.get("guard", false)): return false
	if data.get("jet_firing", false) and not data.get("jet", false): return false
	if data.has("milk") and (not number(data.milk, 100) or data.milk < 0): return false
	if data.has("jet_sequence") and not sequence(data.jet_sequence): return false
	if data.has("jet_origin") and not vector(data.jet_origin, 3, 1000): return false
	if data.has("jet_velocity") and not vector(data.jet_velocity, 3, 100): return false
	if data.has("shot") and not sequence(data.shot): return false
	if data.has("clash") and not sequence(data.clash): return false
	if data.has("shot_origin") and not vector(data.shot_origin, 3, 1000): return false
	if data.has("shot_velocity") and not vector(data.shot_velocity, 3, 60): return false
	if data.has("gun_magazine") and (not sequence(data.gun_magazine) or data.gun_magazine > 9): return false
	if data.has("gun_reload") and (not number(data.gun_reload, 2.0) or data.gun_reload < 0): return false
	if data.has("gun_charge") and (not number(data.gun_charge, 2.0) or data.gun_charge < 0): return false
	if data.has("ricochet") and not sequence(data.ricochet): return false
	if data.has("ricochet_origin") and not vector(data.ricochet_origin, 3, 1000): return false
	if data.has("ricochet_velocity") and not vector(data.ricochet_velocity, 3, 60): return false
	for field in ["owned", "selected", "guard", "active"]:
		if not data.get(field) is bool: return false
	for field in ["aim", "facing"]:
		if not vector(data.get(field), 2, 1.001): return false
	for field in ["charge", "strength", "elapsed", "punch", "cooldown"]:
		if not number(data.get(field), 10) or data[field] < 0: return false
	if data.charge > 1 or data.strength > 1: return false
	return vector(data.get("drop"), 3, 1000)

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
	if not value is Dictionary: return false
	var ver: Variant = value.get("version")
	if not _progress_counter(ver) or ver < 1 or ver > 2: return false
	var xp: Variant = value.get("experience")
	if not _progress_counter(xp): return false
	var practice: Variant = value.get("practice")
	if not practice is Dictionary or practice.size() not in [5, 6]: return false
	for field in ["fist", "sword", "magic", "attack_speed", "defence"]:
		if not _progress_counter(practice.get(field)): return false
	if practice.size() == 6 and not _progress_counter(practice.get("shooting")): return false
	if ver == 2:
		if value.has("stat_points") and not _progress_counter(value.get("stat_points")): return false
		if value.has("granted_level") and not _progress_counter(value.get("granted_level")): return false
		if value.has("stats"):
			var st: Variant = value.get("stats")
			if not st is Dictionary: return false
			for field: Variant in st.values():
				if not _progress_counter(field): return false
	return true

static func _progress_counter(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0 and value <= 100000000 and float(value) == floorf(value)

static func vitals(data: Variant) -> bool:
	return data is Dictionary and number(data.get("stamina"), 100.0 * pow(1.02, 98)) and data.stamina >= 0 and number(data.get("combat_remaining"), 30.0) and data.combat_remaining >= 0

static func endurance(data: Variant) -> bool:
	return data is Dictionary and number(data.get("current"), 100.0) and data.current >= 0 and number(data.get("rest"), 1.2) and data.rest >= 0 and data.get("exhausted") is bool

static func impact(data: Variant) -> bool:
	return data is Dictionary and number(data.get("remaining"), 0.24) and data.remaining >= 0 and vector(data.get("push"), 2, 9.0) and Vector2(data.push[0], data.push[1]).length() <= 9.001

static func _character_level(data: Dictionary) -> int:
	var xp := int(data.get("experience", 0))
	var level := 1
	while level < 99:
		var cost := 100 + 50 * (level - 1) + 25 * (level - 1) * (level - 1)
		if xp < cost: break
		xp -= cost
		level += 1
	return level
