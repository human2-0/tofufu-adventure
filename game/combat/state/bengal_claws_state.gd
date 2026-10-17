class_name BengalClawsState
extends RefCounted
## Optional fields preserve older saves; applying values never resolves hits.

static func capture(combat: PlayerCombat) -> Dictionary:
	return {"paws": combat.claws.selected, "claw_cooldown": combat.claws.cooldown,
		"claw_charge": combat.claws.charge, "claw_charging": combat.claws.charging,
		"claw_dashing": combat.claws.dashing, "claw_remaining": combat.claws.remaining,
		"claw_launch": combat.claws.launch_sequence,
		"claw_sequence": combat.claws.sequence, "claw_origin": [combat.claws.origin.x, combat.claws.origin.y, combat.claws.origin.z],
		"claw_aim": [combat.claws.aim.x, combat.claws.aim.y]}

static func apply(combat: PlayerCombat, state: Dictionary, feedback: bool) -> void:
	var origin: Array = state.get("claw_origin", [0, 0, 0])
	var aim: Array = state.get("claw_aim", [0, 1])
	combat.claws.selected = state.get("paws", false)
	combat.claws.cooldown = state.get("claw_cooldown", 0.0)
	combat.claws.origin = Vector3(origin[0], origin[1], origin[2])
	combat.claws.aim = Vector2(aim[0], aim[1])
	combat.claws.charging = feedback and state.get("claw_charging", false)
	combat.claws.charge = float(state.get("claw_charge", 0.0)) if feedback else 0.0
	combat.claws.dashing = feedback and state.get("claw_dashing", false)
	combat.claws.remaining = float(state.get("claw_remaining", 0.0)) if feedback else 0.0
	combat.claws.launch_sequence = int(state.get("claw_launch", 0))
	if feedback and combat.claws.busy(): BengalRiftVFX.charge(combat)
	var sequence := int(state.get("claw_sequence", 0))
	if feedback and sequence > combat.claws.sequence and combat.claws.cooldown > BengalClaws.COOLDOWN - 1.0:
		var forward := Vector3(combat.claws.aim.x, 0, combat.claws.aim.y)
		BengalRiftVFX.slash(combat, combat.claws.origin + Vector3.UP * 0.55 + forward * 1.2, true, forward)
	combat.claws.sequence = sequence
