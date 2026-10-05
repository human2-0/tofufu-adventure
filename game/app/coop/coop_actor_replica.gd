class_name CoopActorReplica
extends RefCounted
## Applies peer snapshots and presents one actor; state remains on its owner.

static func accept_view(member: CoopActor, state: Dictionary) -> void:
	member.actor.parrot_rest = CoopValues.vector3(state.parrot_rest) if state.get("parrot_rest", []).size() == 3 else Vector3.INF
	if state.has("quests") and state.quests != member.quests.capture(): member.quests.restore(state.quests)
	if member.prediction == null: member.actor.transport_active = bool(state.get("transport", false))
	member.spectating = bool(state.get("spectating", false))
	member.loadout.active_slot = int(state.get("active_slot", 1))
	if member.prediction != null: member.prediction.accept(state)
	if not member.target_state.is_empty() and state.health < member.target_state.health:
		CombatEffects.burst(member, member.actor.global_position, "-%.1f" % (member.target_state.health - state.health), Color("ff9b8c"))

	if not member.target_state.is_empty() and int(state.get("respawns", 0)) > int(member.target_state.get("respawns", 0)) and member.hud != null:
		member.hud.announce("Back at the nursery / Fresh health. Keep exploring together!")
	if not member.target_state.is_empty() and int(state.get("blocks", 0)) > int(member.target_state.get("blocks", 0)):
		CombatEffects.sparks(member, member.actor.position + Vector3(state.aim[0] * 0.65, 0.7, state.aim[1] * 0.65))
	if not member.target_state.is_empty() and member.hud != null:
		var before: Array = member.target_state.get("hits", [0, 0, 0])
		var after: Array = state.get("hits", [0, 0, 0])
		for kind in 3:
			if after[kind] > before[kind]: member.hud.show_damage_hit(kind)
	if state.get("equipment") is Dictionary and state.equipment != member.character_equipment.capture(): member.character_equipment.restore(state.equipment)
	if state.get("inventory") is Array and state.inventory != member.inventory.capture(): member.inventory.restore(state.inventory)
	if member.target_state.is_empty() or state.get("progression", {}) != member.target_state.get("progression", {}):
		member.progression.progress.restore(state.get("progression", {}))
	if state.get("super_dashing", false) and not member.target_state.get("super_dashing", false):
		member.FART_CLOUD.spawn(member.actor.get_parent(), CoopValues.vector3(state.position), [])
	member.combat.vitals.restore(state.combat.get("vitals", {}))
	member.actor.motor.endurance.restore(state.get("endurance", {}))
	member.health.current = state.health
	member.target_state = state
	member._view_age = 0
	member._refresh_hud(state)

static func process(member: CoopActor, delta: float) -> void:
	if member.authority or member.target_state.is_empty(): return
	member._view_age += delta
	var state := member.target_state
	var footsteps := member.actor.get_node_or_null("PlayerFootsteps") as PlayerFootsteps
	if footsteps != null:
		footsteps.present_grounded(state.grounded)
		footsteps.present_dashing(state.dashing)
	var command := PlayerCommand.new()
	command.aim = Vector2(state.aim[0], state.aim[1])
	command.move = Vector2(member.actor.velocity.x, member.actor.velocity.z).limit_length()
	command.face_aim = state.get("facing_locked", false)
	command.attack_held = state.combat.charge > 0
	if member.prediction != null: command = member.prediction.command
	if member.actor.transport_active: command = PlayerCommand.new()
	var aim_locked: bool = command.face_aim or state.combat.guard or command.guard_held or ((state.combat.get("gun", false) or state.combat.get("jet", false)) and command.attack_held)
	member.actor.visuals.attack_facing = Vector2(state.combat.aim[0], state.combat.aim[1]) if state.combat.active else (command.aim if aim_locked else Vector2.ZERO)
	if member.actor.transport_active:
		member.actor.visuals.present(command, Vector3.ZERO, true, false, delta, 0.0, 0.0)
	else:
		member.actor.visuals.present(command, member.actor.velocity, member.actor.is_on_floor() if member.prediction != null else state.grounded, member.actor.motor.is_dashing if member.prediction != null else state.dashing, delta, member.actor.motor.jump_charge if member.prediction != null else state.charge, state.get("clearance", 100.0))
	var view: Dictionary = state.combat.duplicate()
	view.elapsed += minf(member._view_age, 0.1) * member.combat.attack_speed_multiplier
	# One facing for the hand and weapon, including immediate local mouse look.
	var facing := command.aim if aim_locked or command.attack_held else (command.move if not command.move.is_zero_approx() else command.aim)
	view.facing = [facing.x, facing.y]
	CombatState.present(member.combat, view, command.aim if command.move.is_zero_approx() or command.face_aim or command.attack_held else command.move)

	if not command.move.is_zero_approx() and member.actor.visuals.attack_facing.is_zero_approx() and not command.attack_held:
		member.combat.gun.visual.facing = command.move
		member.combat.sotjet.visual.facing = command.move

static func refresh_hud(member: CoopActor, state: Dictionary) -> void:
	if member.hud == null: return
	var combo_count := int(state.combat.get("combo", 0))
	var critical_chance := minf(member.combat.tuning.combo_critical_chance_cap, combo_count * member.combat.tuning.combo_critical_chance_per_hit)
	member.hud.show_health(state.health, member.health.maximum)
	member.hud.show_stamina(member.combat.vitals.current, member.combat.vitals.maximum, member.combat.vitals.combat_remaining)
	member.hud.show_run_stamina(member.actor.motor.endurance.current, RunEndurance.MAXIMUM, member.actor.motor.endurance.exhausted)
	member.hud.show_dash_cooldown(state.cooldown, member.actor.tuning.dash_cooldown)
	member.hud.show_jump_charge(state.charge)
	member.hud.show_charge(state.combat.charge)
	member.hud.show_combo(combo_count, critical_chance)
	member.hud.show_equipment(state.combat.owned, state.combat.selected, state.combat.guard)
	member.hud.show_staff_state(state.combat.get("staff", false), state.combat.get("style", 0) == StaffAttack.TORNADO and state.combat.active, state.combat.cooldown)
	member.hud.show_pod_state(state.combat.get("pod", false), state.combat.get("pod_cooldown", 0.0))
	member.hud.show_gun(state.combat.get("gun", false), state.combat.get("ads", false))
	member.hud.show_gun_status(int(state.combat.get("gun_magazine", SoyGun.MAGAZINE_SIZE)), float(state.combat.get("gun_reload", 0.0)), float(state.combat.get("gun_charge", 0.0)), state.combat.get("gun", false))

static func physics_process(member: CoopActor, delta: float) -> void:
	if member.authority or member.target_state.is_empty(): return
	if member.prediction != null and not member.actor.transport_active: return
	var at := CoopValues.vector3(member.target_state.position)
	member.actor.velocity = CoopValues.vector3(member.target_state.velocity)
	at += member.actor.velocity * minf(member._view_age, 0.1)
	member.actor.position = member.actor.position.lerp(at, 1.0 - exp(-22.0 * delta)) if member.actor.position.distance_to(at) < 5.0 else at
