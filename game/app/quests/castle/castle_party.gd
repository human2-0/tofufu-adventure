class_name CastleParty
extends RefCounted
## Explicit actor membership, health contracts, burn refresh and encounter recovery.

var flow: CastleAdventure
var members: Dictionary = {}
var burns: Dictionary = {}
var fallen: Array[Player] = []
var burn_views: Dictionary = {}

func actors(arena: bool = false) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var candidates: Array = members.values() if not members.is_empty() else [null]
	for member: Variant in candidates:
		var actor: Player = member.actor if member != null else flow.game.player
		var health: Damageable = member.health if member != null else flow.game.health
		if not actor.is_visible_in_tree() or actor.transport_active or health.current <= 0 or actor in fallen: continue
		if arena and (not inside_arena(actor) or key(actor) not in flow.state.participants): continue
		result.append(actor)
	return result

func inside_arena(actor: Player) -> bool:
	var local := flow.castle.to_local(actor.global_position)
	return absf(local.x) < 25 and absf(local.z) < 25 and local.y > 23.8 and local.y < 30

func member_for(actor: Node3D) -> CoopActor:
	for member: CoopActor in members.values():
		if member.actor == actor: return member
	return null

func key(actor: Node3D) -> String:
	for id: String in members:
		if members[id].actor == actor: return id
	return "solo" if members.is_empty() and actor == flow.game.player else ""

func health_for(actor: Node3D) -> Damageable:
	var member := member_for(actor)
	return member.health if member != null else (flow.game.health if actor == flow.game.player else null)

func hurt(actor: Node3D, amount: float, source: Vector3, ignite: bool) -> void:
	if not flow.authoritative or actor not in actors(): return
	var health := health_for(actor)
	var before: int = health.hit_counts[Damageable.HitKind.SLIME]
	var member := member_for(actor)
	if member != null: member.hurt(amount, source)
	elif not flow.game.player.motor.is_dashing and not flow.game.combat.equipment.defend(source, amount):
		if health.damage(amount * flow.game.combat.incoming_damage_multiplier, Vector3.ZERO, Damageable.HitKind.SLIME): health.invulnerability = 0.8
	if ignite and health.hit_counts[Damageable.HitKind.SLIME] > before and health.current > 0 and actor not in fallen:
		burns[key(actor)] = [6.0, 1.0]

func step(delta: float) -> void:
	for id: String in burns.keys():
		var actor: Player = members[id].actor if members.has(id) else (flow.game.player if id == "solo" and members.is_empty() else null)
		if not is_instance_valid(actor) or health_for(actor).current <= 0 or actor.transport_active or not flow.castle.contains(actor.global_position) or cooled(actor):
			burns.erase(id)
			continue
		var timers: Array = burns[id]
		timers[0] -= delta
		timers[1] -= delta
		if timers[1] <= 0:
			timers[1] += 1.0
			var member := member_for(actor)
			var combat: PlayerCombat = member.combat if member != null else flow.game.combat
			health_for(actor).damage(4.0 * combat.incoming_damage_multiplier, Vector3.ZERO, Damageable.HitKind.SLIME)
		if timers[0] <= 0: burns.erase(id)

func cooled(actor: Player) -> bool:
	if TerrainLocomotion.immersion(actor.global_position, flow.game.world) > 0.35: return true
	var at := flow.castle.to_local(actor.global_position)
	if absf(at.y - 24) > 0.8: return false
	for x in [-18.0, 18.0]:
		for z in [-16.0, 16.0]:
			if Vector2(at.x - x, at.z - z).length() < 2.2: return true
	return false

func recover(actor: Player) -> bool:
	if not flow.authoritative or not flow.castle.contains(actor.global_position): return false
	burns.erase(key(actor))
	if flow.encounter.king.active and inside_arena(actor):
		if actor not in fallen: fallen.append(actor)
		var member := member_for(actor)
		if member != null: member.spectating = true
		actor.set_physics_process(false)
		actor.relocate(flow.castle.to_global(Vector3(0, 24.1, -30)))
		return true
	_restore(actor)
	return true

func release_fallen() -> void:
	for actor in fallen:
		if is_instance_valid(actor): _restore(actor)
	fallen.clear()

func _restore(actor: Player) -> void:
	var local := flow.castle.to_local(actor.global_position)
	var deck := clampi(floori(local.y / 8), 0, 3)
	while deck > 0 and not flow.state.gate_open(deck - 1): deck -= 1
	var side := 1.0 if deck % 2 == 0 else -1.0
	actor.relocate(flow.castle.to_global(Vector3(0, deck * 8 + 0.1, side * 24)))
	actor.velocity = Vector3.ZERO
	actor.motor.is_dashing = false
	actor.motor.is_super_dashing = false
	actor.visuals.jump_animation.reset()
	actor.motor.cancel_jump()
	actor.set_physics_process(true)
	var member := member_for(actor)
	if member != null:
		member.spectating = false
		member.respawn_count += 1
		member.combat.reset()
	else: flow.game.combat.reset()
	health_for(actor).restore()

func claim(actor: Player) -> bool:
	var id := key(actor)
	if id.is_empty() or id not in flow.state.participants or id in flow.state.rewarded: return false
	var member := member_for(actor)
	var inventory: PlayerInventory = member.inventory if member != null else flow.game.inventory
	if inventory.pending_items.size() >= 32: return false
	flow.state.rewarded.append(id)
	flow.state.revision += 1
	var item := InventoryItem.from_id("golden_tofu_chunk")
	if inventory.add_item(item, 1) > 0: inventory.pending_items.append(ItemStack.new(item, 1))
	var progress: ActorProgression = member.progression if member != null else flow.game.progression
	progress.progress.award_experience(600)
	flow.state.message = "King Lava's blessing: Golden Tofu and 600 experience. Fire now remembers restraint."
	return true

func present_burns() -> void:
	for art: Variant in burn_views.values():
		if is_instance_valid(art): art.active = false
	for actor: Player in actors():
		var id := actor.get_instance_id()
		if not burn_views.has(id):
			var art := CastleBurnVisual.new()
			actor.add_child(art)
			burn_views[id] = art
		burn_views[id].active = burns.has(key(actor))
	for id: int in burn_views.keys():
		if not is_instance_valid(burn_views[id]): burn_views.erase(id)

func adopt_solo() -> void:
	if not flow.authoritative or members.is_empty(): return
	var local_key := key(flow.game.player)
	if local_key.is_empty(): return
	for ledger: Array[String] in [flow.state.participants, flow.state.rewarded]:
		var index := ledger.find("solo")
		if index >= 0: ledger[index] = local_key
	if flow.state.treasure_claims.has("solo"):
		flow.state.treasure_claims[local_key] = int(flow.state.treasure_claims.get(local_key, 0)) | int(flow.state.treasure_claims.solo)
		flow.state.treasure_claims.erase("solo")
