class_name CastleSnapshot
extends RefCounted
## Preflight all nested state before mutating gates, enemies, rewards or effects.

static func capture(flow: CastleAdventure, live: bool) -> Dictionary:
	var data := {"trial": flow.state.capture()}
	if not live: _personal(data.trial, flow.party.key(flow.game.player))
	if live:
		data["guards"] = flow.encounter.guards.map(func(guard: CastleSentinel) -> Dictionary: return guard.capture())
		data["king"] = flow.encounter.king.capture()
		data["burns"] = flow.party.burns.duplicate(true)
		data["fallen"] = flow.party.fallen.map(func(actor: Player) -> String: return flow.party.key(actor))
	return data

static func _personal(trial: Dictionary, key: String) -> void:
	if key.is_empty() or key == "solo": return
	# Personal saves follow this actor back offline; world/checkpoint identities stay stable.
	if trial.treasure_claims.has(key):
		trial.treasure_claims["solo"] = int(trial.treasure_claims.get("solo", 0)) | int(trial.treasure_claims[key])
		trial.treasure_claims.erase(key)
	for ledger: Array in [trial.participants, trial.rewarded]:
		if key not in ledger: continue
		if "solo" in ledger: ledger.erase(key)
		else: ledger[ledger.find(key)] = "solo"

static func restore(flow: CastleAdventure, data: Dictionary, live: bool) -> void:
	if not CastleProtocol.valid(data, live): return
	if live:
		for i in 9:
			if int(data.guards[i].body[4]) >= flow.encounter.guards[i].route.size(): return
	flow.state.restore(data.trial)
	flow.party.adopt_solo()
	if not data.trial.has("message"): flow.state.message = "KING LAVA: You taught the flame to remember. Accept my blessing." if flow.state.completed else ("KING LAVA: Speak again when you are ready to face the fire." if flow.state.introduced else "Restore the three royal wards.")
	for i in 9:
		var guard := flow.encounter.guards[i]
		if live: guard.apply(data.guards[i], flow.authoritative)
		else:
			guard.global_position = guard.route[guard.home]
			guard.waypoint = guard.home
			guard.target.current = guard.target.maximum
			guard.tactics = CastleSentinelTactics.new()
			guard.spells.clear()
			guard.set_alive(flow.state.defeated_guards & (1 << i) == 0)
	if live:
		flow.encounter.king.apply(data.king, flow.authoritative)
		flow.party.burns = data.burns.duplicate(true)
		flow.party.fallen.clear()
		for id: String in data.fallen:
			if flow.party.members.has(id):
				var member: CoopActor = flow.party.members[id]
				flow.party.fallen.append(member.actor)
				member.actor.set_physics_process(false)
				member.spectating = true
	else:
		flow.encounter.king.reset()
		if flow.state.completed: flow.encounter.king.pose = "defeat"
		flow.party.burns.clear()
	flow.encounter.arena_gate.set_open(not flow.encounter.king.active)
	# Restores/initial joins set scenery directly; subsequent guest changes acknowledge it.
	if not live or flow.authoritative or not flow.replica_initialized:
		flow.treasure.present(false)
		for floor_node in flow.castle.floors: floor_node.trial.feedback.last_revision = -1
	flow.replica_initialized = live
	flow.present_state()
	if not live and flow.castle.contains(flow.game.player.global_position):
		var local := flow.castle.to_local(flow.game.player.global_position)
		var deck := clampi(floori(local.y / 8), 0, 3)
		if deck > 0 and not flow.state.gate_open(deck - 1):
			flow.game.player.relocate(flow.castle.to_global(Vector3(0, 0.1, 24)))
