class_name CoopDuelFighters
extends RefCounted
## Saves party state and applies equal duel rules to the two selected actors.

var session: CoopSession
var saved_states: Dictionary = {}
var saved_actions: Dictionary = {}

func save_entry(participants: Array[String], defeated_handler: Callable) -> void:
	saved_states.clear()
	saved_actions.clear()
	for key in participants:
		var member: CoopActor = session.roster.party[key]
		saved_states[key] = member.capture()
		saved_actions[key] = {"drop": member.combat.equipment.drop_item, "pickup": member.combat.equipment.pickup_item}
		member.combat.equipment.drop_item = Callable()
		member.combat.equipment.pickup_item = Callable()
		_set_training(member, false)
		member.duel_defeated = defeated_handler.bind(key)
		member.health.invulnerability = maxf(member.health.invulnerability, 6.0)

func filter_targets(participants: Array[String]) -> void:
	for key: String in session.roster.party:
		var member: CoopActor = session.roster.party[key]
		var fighter := key in participants
		var ignored: Array[CollisionObject3D] = []
		if fighter:
			for other_key: String in session.roster.party:
				if other_key not in participants: ignored.append(session.roster.party[other_key].actor)
		var targets: Array[Damageable] = []
		if fighter:
			var foe := participants[1 - participants.find(key)]
			targets.append(session.roster.party[foe].health)
		member.combat.targets = targets
		member.combat.gun.targets = targets.duplicate()
		member.combat.gun.friends.clear()
		member.combat.gun.ignored_bodies.assign(ignored)
		member.combat.sotjet.flow.targets = targets.duplicate()
		member.combat.sotjet.flow.ignored_bodies.assign(ignored)
		for child in member.combat.gun.get_children():
			if child is SoyProjectile: child.ignored_bodies.assign(ignored)
		var opponents: Array[PlayerCombat] = []
		for foe_key in participants:
			if key in participants and foe_key != key: opponents.append(session.roster.party[foe_key].combat)
		member.combat.clash.opponents = opponents

func start_round(participants: Array[String], spawns: Array[Vector3]) -> void:
	for index in 2:
		var member: CoopActor = session.roster.party[participants[index]]
		_apply_equal_loadout(member)
		_clear_shots(member)
		member.actor.relocate(spawns[index] + Vector3.UP * 0.12)
		member.actor.velocity = Vector3.ZERO
		member.actor.motor.is_dashing = false
		member.actor.motor.is_super_dashing = false
		member.actor.motor.cooldown_remaining = 0.0
		member.respawn_count += 1
		member.health.restore()
		member.health.invulnerability = 0.0
		member.combat.vitals.reset()
		member.actor.motor.endurance.reset()

func contain(participants: Array[String]) -> void:
	var arena := session.game.world.duel_arena as FarmDuelArena
	for index in participants.size():
		var key := participants[index]
		if not session.roster.party.has(key): continue
		var member: CoopActor = session.roster.party[key]
		if arena.contains_arena(member.actor.global_position): continue
		var destination := arena.return_position(index)
		if not member.actor.relocate(destination): member.actor.global_position = destination
		member.actor.velocity = Vector3.ZERO
		member.actor.motor.is_dashing = false
		member.actor.motor.is_super_dashing = false
		member.actor.motor.dash_remaining = 0.0
		member.actor.motor.cancel_jump()
		member.actor.motor.cancel_dash_charge()
		member.actor.ability_velocity = Callable()
		member.health.invulnerability = maxf(member.health.invulnerability, 0.35)

func clear_projectiles(participants: Array[String]) -> void:
	for key in participants:
		if session.roster.party.has(key): _clear_shots(session.roster.party[key])

func clear_party_projectiles() -> void:
	for member: CoopActor in session.roster.party.values(): _clear_shots(member)

func finish(participants: Array[String]) -> void:
	session.roster.rebuild_targets()
	for key in participants:
		if not session.roster.party.has(key): continue
		var member: CoopActor = session.roster.party[key]
		member.duel_defeated = Callable()
		if saved_states.has(key): member.restore(saved_states[key])
		_restore_actions(member, key)
		_leave_pad(member, participants.find(key))
		_clear_shots(member)
	saved_states.clear()
	saved_actions.clear()

func checkpoint_party(current: Dictionary) -> Dictionary:
	var result := current.duplicate(true)
	for key: String in saved_states:
		result[key] = saved_states[key].duplicate(true)
	return result

func cancel_entry(participants: Array[String]) -> void:
	session.roster.rebuild_targets()
	for key in participants:
		if not session.roster.party.has(key): continue
		var member: CoopActor = session.roster.party[key]
		var state: Dictionary = saved_states.get(key, {})
		if not state.is_empty():
			state.position = CoopValues.array3(member.actor.position)
			state.velocity = CoopValues.array3(member.actor.velocity)
			member.restore(state)
		member.duel_defeated = Callable()
		_restore_actions(member, key)
	saved_states.clear()
	saved_actions.clear()

func abort(participants: Array[String]) -> void:
	session.roster.rebuild_targets()
	for key in participants:
		if not session.roster.party.has(key):
			if saved_states.has(key):
				var departed: Dictionary = saved_states[key].duplicate(true)
				_set_saved_exit_position(departed, participants.find(key))
				session.roster.saved_states[key] = departed
			continue
		var member: CoopActor = session.roster.party[key]
		member.duel_defeated = Callable()
		if saved_states.has(key): member.restore(saved_states[key])
		_restore_actions(member, key)
		_leave_pad(member, participants.find(key))
		_clear_shots(member)
	saved_states.clear()
	saved_actions.clear()

func _apply_equal_loadout(member: CoopActor) -> void:
	var base := CharacterProgress.new()
	member.progression.progress.restore(base.capture())
	for slot in ["helmet", "armor", "legs", "boots", "accessory", "support_1", "support_2", "support_3", "support_4"]:
		member.character_equipment.set_slot(slot, null)
	member.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("knife"), 1))
	member.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))
	member.loadout.active_slot = 2
	member.loadout.refresh(false)
	member.combat.gun.magazine = SoyGun.MAGAZINE_SIZE
	member.combat.gun.reload_remaining = 0.0
	member.health.armor_multiplier = 1.0

func _clear_shots(member: CoopActor) -> void:
	for child in member.combat.gun.get_children():
		if child is SoyProjectile: child.queue_free()
	member.combat.sotjet.flow.clear()

func _leave_pad(member: CoopActor, index: int) -> void:
	var destination: Vector3 = (session.game.world.duel_arena as FarmDuelArena).pad_exit_position(index)
	if not member.actor.relocate(destination): member.actor.global_position = destination
	member.actor.velocity = Vector3.ZERO
	member.actor.motor.is_dashing = false
	member.actor.motor.is_super_dashing = false
	member.actor.motor.dash_remaining = 0.0
	member.actor.motor.cancel_jump()
	member.actor.motor.cancel_dash_charge()
	member.actor.ability_velocity = Callable()

func _set_saved_exit_position(state: Dictionary, index: int) -> void:
	var destination: Vector3 = (session.game.world.duel_arena as FarmDuelArena).pad_exit_position(index)
	state.position = CoopValues.array3(destination)
	state.velocity = [0.0, 0.0, 0.0]

func _restore_actions(member: CoopActor, key: String) -> void:
	if saved_actions.has(key):
		member.combat.equipment.drop_item = saved_actions[key].drop
		member.combat.equipment.pickup_item = saved_actions[key].pickup
		saved_actions.erase(key)
	_set_training(member, true)

func _set_training(member: CoopActor, connected: bool) -> void:
	var progress := member.progression.progress
	var sources: Array[Signal] = [member.combat.weapon_trained, member.combat.gun.weapon_trained, member.combat.sotjet.weapon_trained]
	for source in sources:
		if connected and not source.is_connected(progress.weapon_hit): source.connect(progress.weapon_hit)
		elif not connected and source.is_connected(progress.weapon_hit): source.disconnect(progress.weapon_hit)
	var defended := member.combat.equipment.defended
	if connected and not defended.is_connected(progress.defended): defended.connect(progress.defended)
	elif not connected and defended.is_connected(progress.defended): defended.disconnect(progress.defended)
