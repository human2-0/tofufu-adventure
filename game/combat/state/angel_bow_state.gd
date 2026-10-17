class_name AngelBowState
extends RefCounted
## Optional legacy-safe bow clocks and sequenced cosmetic events.

static func capture(bow: AngelBow) -> Dictionary:
	return {"bow": bow.selected, "bow_reload": bow.reload_remaining, "bow_charge": bow.charge,
		"bow_cooldown": bow.cooldown, "bow_shot": bow.sequence, "bow_fire": bow.empowered,
		"bow_origin": _array(bow.origin), "bow_velocity": _array(bow.velocity),
		"bow_burst": bow.burst_sequence, "bow_at": _array(bow.burst_at)}

static func apply(bow: AngelBow, state: Dictionary, feedback: bool) -> void:
	bow.selected = state.get("bow", false)
	bow.visual.visible = bow.selected
	bow.reload_remaining = state.get("bow_reload", 0.0)
	bow.charge = state.get("bow_charge", 0.0) if feedback else 0.0
	bow.cooldown = state.get("bow_cooldown", 0.0)
	var origin := _vector(state.get("bow_origin", [0, 0, 0]))
	var velocity := _vector(state.get("bow_velocity", [0, 0, 0]))
	var at := _vector(state.get("bow_at", [0, 0, 0]))
	if feedback:
		bow.visual.facing = Vector2(state.facing[0], state.facing[1])
		bow.present_shot(int(state.get("bow_shot", 0)), origin, velocity, state.get("bow_fire", false))
		bow.present_burst(int(state.get("bow_burst", 0)), at)
	else:
		bow.origin = origin
		bow.velocity = velocity
		bow.empowered = state.get("bow_fire", false)
		bow.sequence = int(state.get("bow_shot", 0))
		bow.burst_sequence = int(state.get("bow_burst", 0))
		bow.burst_at = at

static func _array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func _vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])
