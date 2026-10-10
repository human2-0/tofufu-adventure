extends SceneTree
## Guest commands cross the room boundary; only host collision/health rules run.

var failures: int = 0
var host: PlaytestRoom
var guest: PlaytestRoom
var host_game: Node3D
var guest_game: Node3D
var host_session: CoopSession
var guest_session: CoopSession
var input: CoopTestInput
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
const OBSERVER := "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func drop_id(pool: WorldItemPool, item_id: String) -> int:
	for drop: WorldItemDrop in pool.drops.values():
		if drop.item_id == item_id: return drop.drop_id
	return 0

func _run() -> void:
	host = PlaytestRoom.new()
	guest = PlaytestRoom.new()
	root.add_child(host)
	root.add_child(guest)
	host.local_key = HOST
	guest.local_key = GUEST
	host.peers[GUEST] = {"name": "Guest", "hosting": false, "busy": false}
	guest.peers[HOST] = {"name": "Host", "hosting": true, "busy": false}
	host.send_packet = func(_key: String, data: Dictionary) -> void: guest.receive({"type": "packet", "key": HOST, "data": JSON.parse_string(JSON.stringify(data))})
	guest.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": GUEST, "data": JSON.parse_string(JSON.stringify(data))})
	host.create_room()
	guest.join_room(HOST)
	host.begin()
	host_session = _game(host)
	guest_session = _game(guest)
	host_game = host_session.game
	guest_game = guest_session.game
	input = CoopTestInput.new()
	root.add_child(input)
	guest_session.roster.local_input = input
	(host_session.roster.local_input as LocalPlayerInput).enabled = false
	await ticks(15)
	var remote := host_session.roster.party[GUEST]
	var replica := guest_session.roster.party[GUEST]
	var before_shop := remote.actor.position
	remote.inventory.add_item(InventoryItem.currency("mature_bean"), 1)
	guest_game.merchant._request("sotjet")
	await ticks(10)
	check(remote.inventory.count_item("mature_bean") == 1, "remote purchase rejects out-of-range buyer")
	remote.actor.relocate(host_game.world.weapon_merchant.global_position + Vector3(0, 0.1, 1.5))
	await ticks(15)
	guest_game.merchant._request("sotjet")
	await ticks(15)
	check(remote.inventory.count_item("mature_bean") == 1 and replica.inventory.count_item("mature_bean") == 1, "host grants free gear and synchronizes the unchanged Mature Bean balance")
	check(replica.inventory.count_item("sotjet") == 1, "guest purchase creates a weapon in the bag")
	guest_game.merchant._request_sale(1, "sotjet")
	await ticks(12)
	check(remote.inventory.count_item("mature_bean") == 2 and replica.inventory.count_item("mature_bean") == 2 and replica.inventory.get_slot(0).item.id == "mature_bean", "guest sale credits mature beans and removes the sold item on both peers")
	var level_five_experience := CharacterProgress.threshold(5, true)
	remote.progression.progress.award_experience(level_five_experience)
	await ticks(8)
	check(remote.character_equipment.wearer_level == 5 and replica.character_equipment.wearer_level == 5, "level-five armor requirement follows guest progression")
	for slot_name in ["helmet", "armor", "legs", "boots"]:
		var apparel_id := "bright_leaf_%s" % slot_name
		guest_game.merchant._request(apparel_id)
		await ticks(12)
		var apparel_slot := -1
		for slot in replica.inventory.capacity:
			var stack := replica.inventory.get_slot(slot)
			if stack != null and stack.item != null and stack.item.id == apparel_id:
				apparel_slot = slot
				break
		check(apparel_slot >= 0, "%s purchase synchronizes from Kaji" % apparel_id)
		guest_game.inventory_window.execute_transfer("inventory", apparel_slot, "equipment", slot_name)
		await ticks(12)
	check(remote.actor.visuals.worn_set == "bright_leaf" and replica.actor.visuals.worn_set == "bright_leaf" and is_equal_approx(remote.health.armor_multiplier, 0.90), "host equipment sync shows the complete set and protection on both players")
	remote.inventory.set_slot(0, ItemStack.new(InventoryItem.create_edamame(), 100))
	remote.inventory.refining_unlocked = true
	await ticks(8)
	check(replica.inventory.get_slot(0).count == 100, "100 stack replicates")
	guest_game.inventory_window._request_conversion(0, "edamame")
	await ticks(8)
	check(remote.inventory.get_slot(0).item.id == "mature_bean" and replica.inventory.get_slot(0).item.id == "mature_bean", "guest right-click refine is host-authoritative and replicated")
	guest_game.inventory_window._request_conversion(0, "edamame")
	await ticks(8)
	check(remote.inventory.count_item("mature_bean") == 1, "stale refine request cannot duplicate tender")
	remote.inventory.set_slot(0, null) # Remove the shop fixture before stacking checks.
	remote.actor.relocate(before_shop)
	await ticks(10)
	check(guest_game.inventory == replica.inventory and guest_game.character_equipment == replica.character_equipment, "window shares local co-op inventory")
	remote.inventory.add_item(InventoryItem.create_edamame(), 3)
	await ticks(8)
	guest_game.inventory_window.execute_transfer("inventory", 0, "inventory", 1)
	check(replica.inventory.get_slot(1) == null, "guest transfer awaits host outcome")
	await ticks(8)
	check(remote.inventory.get_slot(1) != null, "host applies guest transfer")
	check(replica.inventory.get_slot(1) != null, "guest receives bag transfer")
	guest.send_game(HOST, {"type": "inventory_transfer", "sequence": 1, "src": "inventory", "src_id": 1, "dst": "inventory", "dst_id": 0})
	await ticks(3)
	check(remote.inventory.get_slot(0) == null, "replayed transfer cannot move currency")
	guest_game.inventory_window.drop_requested.emit("inventory", 1)
	for retry in 24:
		if drop_id(guest_game.world_items.pool, "edamame") != 0: break
		await ticks(1)
	check(remote.inventory.get_slot(1) == null and drop_id(guest_game.world_items.pool, "edamame") != 0, "guest currency stack drops through authority")
	var stack_id: int = drop_id(host_game.world_items.pool, "edamame")
	input.pickup_id = stack_id
	input.pickup = true
	await ticks(10)
	check(remote.inventory.count_item("edamame") == 3 and drop_id(guest_game.world_items.pool, "edamame") == 0, "guest can recover dropped stack through exact focused ID")
	input.pickup_id = -1
	# Clear fixture beans before existing pickup assertions.
	remote.inventory.remove_item("edamame", 3)
	await ticks(8)
	# Grandma quests use authenticated guest intents and personal authoritative rewards.
	guest_game.quest_giver._on_quest_accepted()
	await ticks(6)
	check(remote.quests.status == QuestState.Status.NOT_STARTED, "Grandma rejects distant quest acceptance")
	var grandma_at: Vector3 = host_game.world.quest_npc.global_position + Vector3(0, 0.1, -1.5)
	remote.actor.relocate(grandma_at)
	guest_game.player.relocate(grandma_at)
	await ticks(6)
	guest_game.quest_giver._on_quest_accepted()
	await ticks(8)
	check(remote.quests.status == QuestState.Status.IN_PROGRESS and guest_game.quest_giver.quest.status == QuestState.Status.IN_PROGRESS, "guest acceptance synchronizes personal quest state")
	remote.quests.current_count = 49
	host_game.encounters.mob_defeated.emit(Vector3.ZERO)
	await ticks(8)
	check(guest_game.quest_giver.quest.status == QuestState.Status.COMPLETED and host_game.quest_giver.quest.status == QuestState.Status.NOT_STARTED, "guest kill completion does not change another character's quest")
	guest_game.quest_giver._on_reward_claimed()
	await ticks(8)
	guest_game.quest_giver._on_reward_claimed()
	await ticks(8)
	check(remote.inventory.count_item("edamame") == 100 and remote.quests.status == QuestState.Status.REWARDED, "Grandma grants the guest reward exactly once")
	check(replica.inventory.count_item("edamame") == 100, "quest currency returns in the authoritative guest snapshot")
	remote.inventory.remove_item("edamame", 100)
	var depot_at: Vector3 = host_game.world.seed_bank.to_global(MeadowBarn.table_position(0) + MeadowBarn.front(0) * 1.1 + Vector3.DOWN * 0.7)
	remote.actor.relocate(depot_at)
	remote.actor.velocity = Vector3.ZERO
	guest_game.player.relocate(depot_at)
	guest_game.player.velocity = Vector3.ZERO
	remote.inventory.set_slot(2, ItemStack.new(InventoryItem.create_edamame(), 5))
	await ticks(8)
	check(host_game.seed_storage.nearby(remote.actor), "host recognizes the guest within depot reach")
	var quick_status: String = guest_game.inventory_window.quick_transfer_handler.call("inventory", 2)
	check(quick_status == "Storage transfer requested.", "nearby guest can request a depot quick move")
	var host_inventory: CoopInventory
	for child in host_session.get_children():
		if child is CoopInventory: host_inventory = child
	check(host_inventory != null and host_inventory._pending.has(GUEST), "host queues the guest quick-storage intent")
	await ticks(12)
	check(remote.inventory.get_slot(2) == null and host_game.seed_storage.chest.get_slot(0).count == 5, "guest quick-storage request moves a bag stack on the host")
	check(guest_game.seed_storage.chest.get_slot(0) != null and guest_game.seed_storage.chest.get_slot(0).count == 5, "host chest snapshot returns the quick-storage result")
	remote.actor.relocate(before_shop)
	guest_game.player.relocate(before_shop)
	await ticks(8)
	# Guest intent must collide on the host, then converge to that stopped pose.
	host_game.player.position = Vector3(0, 0.05, 2)
	remote.actor.position = Vector3(-2, 0.05, 2)
	remote.actor.velocity = Vector3.ZERO
	input.move = Vector2.RIGHT
	await ticks(50)
	check(remote.actor.position.x < host_game.player.position.x - 0.79, "guest movement cannot pass through host player")
	input.move = Vector2.ZERO
	await ticks(15)
	check(replica.actor.position.distance_to(remote.actor.position) < 0.15, "guest view converges to authoritative blocked position")
	host_game.player.position = Vector3(0, 0.05, 0)
	var dummy: PracticeDummy = host_game.encounters.dummy_nodes[0]
	remote.actor.position = dummy.position + Vector3(0, 0.05, 1.4)
	remote.actor.velocity = Vector3.ZERO
	await ticks(15)
	input.attack = true
	await ticks(12)
	input.attack = false
	await ticks(35)
	check(remote.progression.progress.practice.sword == 1 and replica.progression.progress.practice.sword == 1, "host awards guest sword practice and replicates it")
	check(host_game.progression.progress.practice.sword == 0, "guest practice does not train host")
	check(dummy.hit_count == 1, "guest knife hits exactly once through host collision queries")
	check(guest_game.encounters.dummy_nodes[0].target.current == dummy.target.current, "dummy health replicates")
	remote.actor.position = dummy.position + Vector3(0, 0.05, 1.1)
	remote.actor.velocity = Vector3.ZERO
	input.punch = true
	await ticks(4)
	input.punch = false
	await ticks(10)
	check(dummy.hit_count == 2, "guest punch runs on host")
	check(remote.progression.progress.practice.fist == 1 and replica.progression.progress.practice.fist == 1, "guest fist practice replicates")
	input.guard = true
	await ticks(30)
	remote.hurt(12, remote.actor.position + Vector3(0, 0, -1))
	check(is_equal_approx(remote.health.current, remote.health.maximum), "guest forward guard blocks damage")
	remote.hurt(12, remote.actor.position + Vector3(0, 0, 1))
	await ticks(10)
	check(remote.progression.progress.practice.defence == 1 and replica.progression.progress.practice.defence == 1, "only the successful guard trains defence")
	check(is_equal_approx(remote.health.current, remote.health.maximum - 10.8) and is_equal_approx(replica.health.current, remote.health.current), "rear hit is reduced by ten percent for the armored guest")
	input.guard = false
	input.drop = true
	await ticks(10)
	check(not remote.combat.equipment.knife_owned and drop_id(guest_game.world_items.pool, "knife") != 0, "guest dropped knife appears on both peers")
	input.pickup = true
	await ticks(10)
	check(remote.combat.equipment.knife_owned and replica.combat.equipment.knife_owned, "guest retrieves own knife")
	# A host-owned world drop is collectible by a guest, with one shared outcome.
	host_game.player.position = remote.actor.position + Vector3(0.8, 0, 0)
	host_game.combat.equipment.step(Vector2.UP, false, false, true, false, 2, 0.016)
	var shared_id: int = host_game.combat.equipment.dropped.drop_id
	await ticks(8)
	check(guest_game.world_items.pool.drops.has(shared_id), "host gun appears in guest shared drop pool")
	input.pickup_id = shared_id
	input.pickup = true
	await ticks(10)
	check(remote.inventory.count_item("soy_gun") == 1 and replica.inventory.count_item("soy_gun") == 1, "guest stores another player's gun in bag when both combat slots are occupied")
	check(not host_game.combat.equipment.gun_owned and not guest_game.world_items.pool.drops.has(shared_id), "original owner stays unarmed and consumed drop disappears")
	input.pickup = true
	await ticks(8)
	check(not host_game.world_items.pool.drops.has(shared_id), "repeated pickup cannot recreate consumed item")
	# Restore fixture ownership for the independent friendly-fire checks below.
	host_game.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))
	input.pickup_id = -1
	input.slot = 1
	await ticks(3)
	var prop: HarvestProp = host_game.encounters.prop_nodes[0]
	prop.target.damage(999)
	await ticks(10)
	check(guest_game.encounters.prop_nodes[0].visible and guest_game.encounters.prop_nodes[0].target.current == 0
		and guest_game.encounters.props == 1, "shared harvest leaves a visible growing soy plant")
	var bean: SoybeanPickup = host_game.encounters.add_pickup(host_game.encounters.next_pickup_id, remote.actor.position)
	bean._age = 1
	await ticks(35)
	check(host_game.encounters.beans == 1 and remote.inventory.count_item("edamame") == 1, "nearest guest collects edamame into inventory exactly once")
	check(guest_game.encounters.beans == 1 and remote.inventory.count_item("edamame") == 1, "loot outcome replicates to inventory count")
	host_game.encounters.mob_nodes[0].target.damage(999)
	await ticks(10)
	check(guest_game.encounters.experience == 25 and not guest_game.encounters.mob_nodes[0].visible, "shared enemy death and EXP")
	check(remote.progression.progress.experience == level_five_experience + 25 and host_game.progression.progress.experience == 25, "party EXP awards every active character once")
	check(replica.progression.progress.experience == level_five_experience + 25, "guest character EXP survives world snapshot application")
	remote.health.invulnerability = 0
	remote.health.damage(999)
	await ticks(10)
	check(is_equal_approx(remote.health.current, remote.health.maximum) and remote.actor.position.x < 1, "guest defeat respawns safely")
	# Both directions of gun friendly fire cross real room JSON and host physics.
	# Death may randomly drop apparel; restore the independent armor fixture.
	for slot_name in ["helmet", "armor", "legs", "boots"]:
		remote.character_equipment.set_slot(slot_name, ItemStack.new(InventoryItem.apparel("bright_leaf_%s" % slot_name), 1))
	remote = host_session.roster.party[GUEST]
	replica = guest_session.roster.party[GUEST]
	remote.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))
	remote.loadout.select(2)
	host_game.player.position = Vector3(0, 0.2, 2)
	remote.actor.position = Vector3(0, 0.2, -3)
	host_game.combat.vitals.engage()
	remote.combat.vitals.engage()
	host_game.health.current = 100
	host_game.health.invulnerability = 0
	remote.health.current = 100
	remote.health.invulnerability = 0
	await ticks(12)
	input.aim = Vector2.DOWN
	input.aim_point = host_game.player.position + Vector3.UP * 0.55
	input.slot = 2
	input.guard = true
	input.attack = true
	await ticks(7)
	input.attack = false
	await ticks(15)
	var expected_host_health: float = 100.0 - 20.0 * remote.combat.gun.damage_multiplier * host_game.combat.incoming_damage_multiplier * host_game.health.armor_multiplier
	check(is_equal_approx(host_game.health.current, expected_host_health), "level-five guest soybean damage reaches the host (%.2f)" % host_game.health.current)
	check(is_equal_approx(guest_session.roster.party[HOST].health.current, expected_host_health), "host friendly-fire health replicates to guest")
	check(replica.combat.gun.selected, "guest gun slot is replicated")
	host_game.combat.gun.selected = true
	host_game.combat.equipment.knife_selected = false
	host_game.combat.gun.tuning.aim_spread_degrees = 0
	host_game.combat.gun.step(true, true, Vector2.UP, remote.actor.position + Vector3.UP * 0.98, 0.02)
	await ticks(18)
	check(is_equal_approx(remote.health.current, 64.0) and is_equal_approx(replica.health.current, 64.0), "armored guest reduces the host headshot and replicates health (remote %.2f, replica %.2f)" % [remote.health.current, replica.health.current])
	var saved := CoopCheckpoint.capture(host_session)
	check(CoopCheckpoint.valid(saved), "full checkpoint validates")
	var store := SaveStore.new()
	store.extra_validator = CoopCheckpoint.valid
	store.directory = "user://coop-test-%d" % Time.get_ticks_usec()
	var record := AdventureSnapshot.capture(host_game, "Co-op test", 12)
	record.coop = saved
	check(store.write_slot(0, record), "co-op checkpoint atomically saves")
	var loaded_progress := CharacterProgress.new()
	loaded_progress.restore(store.read_slot(0).coop.party[GUEST].progression)
	check(loaded_progress.capture() == remote.progression.progress.capture(), "guest skills and partial practice survive disk round trip")
	check(store.read_slot(0).coop.world.experience == 25, "co-op progress survives disk round trip")
	host_game.encounters.experience = 0
	CoopWorld.apply(host_game, saved.world, false)
	check(host_game.encounters.experience == 25, "world progress restores")
	var old_position := remote.actor.position
	guest.leave()
	await ticks(3)
	check(not host_session.roster.party.has(GUEST) and host_session.roster.saved_states.has(GUEST), "disconnect preserves character checkpoint")
	guest.join_room(HOST)
	await ticks(3)
	check(guest.playing and host_session.roster.party.has(GUEST), "join-in-progress accepted")
	remote = host_session.roster.party[GUEST]
	replica = guest_session.roster.party[GUEST]
	check(host_session.roster.party[GUEST].progression.progress.capture() == saved.party[GUEST].progression, "rejoining restores guest progression without duplicate EXP")
	check(host_session.roster.actors[GUEST].position.distance_to(old_position) < 0.5, "reconnecting identity restores position")
	var duel_pads: Array[Vector3] = host_game.world.duel_arena.pad_positions()
	if remote.inventory.capacity < 1: remote.inventory.set_capacity(1)
	var pending_slot := -1
	for slot in remote.inventory.capacity:
		if remote.inventory.get_slot(slot) != null:
			pending_slot = slot
			break
	if pending_slot < 0:
		pending_slot = 0
		remote.inventory.set_slot(pending_slot, ItemStack.new(InventoryItem.create_edamame(), 1))
	check(host_inventory != null, "host inventory sync is available for duel queue checks")
	var pending_item_id: String = remote.inventory.get_slot(pending_slot).item.id
	var drops_before_queue: int = host_game.world_items.pool.drops.size()
	var pending_transfer := {"type": "inventory_transfer", "sequence": int(host_inventory._seen.get(GUEST, 0)) + 1,
		"src": "inventory", "src_id": pending_slot, "dst": "world", "dst_id": 0}
	host_inventory._packet(GUEST, pending_transfer)
	var stale_host_shot := SoyProjectile.new()
	host_game.combat.gun.add_child(stale_host_shot)
	var stale_guest_shot := SoyProjectile.new()
	stale_guest_shot.authoritative = false
	guest_game.combat.gun.add_child(stale_guest_shot)
	host_game.player.relocate(duel_pads[0] + Vector3.UP * 0.26)
	remote.actor.relocate(duel_pads[1] + Vector3.UP * 0.26)
	host_game.player.velocity = Vector3.ZERO
	remote.actor.velocity = Vector3.ZERO
	host_game.player.motor.endurance.current = 40
	host_game.player.motor.endurance.rest_remaining = 1.2
	remote.actor.motor.endurance.current = 22
	remote.actor.motor.endurance.rest_remaining = 1.2
	remote.actor.motor.endurance.exhausted = true
	await ticks(1)
	check(host_session.duel.phase == "entry" and not host_inventory._pending.has(GUEST), "duel entry discards a fighter's already queued inventory action")
	check(not is_instance_valid(stale_host_shot), "duel entry clears live host soy projectiles")
	await ticks(3)
	check(host_session.duel.phase == "entry" and host_session.duel.participants == [HOST, GUEST], "distinct players on both village tiles start the duel countdown")
	check(remote.inventory.get_slot(pending_slot) != null and remote.inventory.get_slot(pending_slot).item.id == pending_item_id and host_game.world_items.pool.drops.size() == drops_before_queue, "discarded inventory action does not mutate the fighter bag")
	var execution_probe := pending_transfer.duplicate(true)
	execution_probe.sequence = int(host_inventory._seen.get(GUEST, 0)) + 1
	host_inventory._pending[GUEST] = [execution_probe]
	host_inventory._physics_process(0.016)
	check(remote.inventory.get_slot(pending_slot) != null and remote.inventory.get_slot(pending_slot).item.id == pending_item_id and host_game.world_items.pool.drops.size() == drops_before_queue, "queued fighter action is rechecked and discarded at execution")
	host_session.duel.countdown = 0.01
	guest_session.duel.present(host_session.duel.capture())
	check(stale_guest_shot.is_queued_for_deletion(), "duel entry clears live cosmetic soy projectiles on guests")
	await ticks(3)
	check(host_session.duel.phase == "fight" and host_session.duel.round_number == 1, "five-to-one countdown teleports both players into the arena")
	var duel_arena: FarmDuelArena = host_game.world.duel_arena
	check(FarmDuelArena.ARENA_HALF_SIZE == Vector2(21, 17) and duel_arena.get_node("Audience").get_child_count() >= 32, "expanded arena has audience stands on all sides")
	var spawns: Array[Vector3] = duel_arena.spawn_positions()
	var spawn_sight_ray := PhysicsRayQueryParameters3D.create(spawns[0] + Vector3.UP * 1.4, spawns[1] + Vector3.UP * 1.4, 1)
	check(not host_game.get_world_3d().direct_space_state.intersect_ray(spawn_sight_ray).is_empty(), "crate cover blocks line of sight between both spawns")
	check(host_game.health.maximum == 100.0 and remote.health.maximum == 100.0 and host_game.combat.vitals.current == 100.0 and remote.combat.vitals.current == 100.0, "duel starts with equal basic HP and SP")
	check(host_game.player.motor.endurance.current == 100 and remote.actor.motor.endurance.current == 100 and not remote.actor.motor.endurance.exhausted, "duel gives both fighters equal fresh running reserve")
	check(host_game.progression.progress.level() == 1 and remote.progression.progress.level() == 1 and host_game.health.armor_multiplier == 1.0 and remote.health.armor_multiplier == 1.0, "duel removes progression and armor advantages")
	check(host_game.combat.gun.selected and remote.combat.gun.selected and remote.character_equipment.get_slot("combat_2").item.id == "soy_gun", "both players receive the same knife and soy gun duel kit")
	check(DuelProtocol.valid(host_session.duel.capture(), host.members), "duel status passes the bounded co-op protocol")
	var guest_duel_entry: Dictionary = host_session.duel._fighters.saved_states[GUEST].duplicate(true)
	var active_checkpoint := CoopCheckpoint.capture(host_session)
	check(CoopCheckpoint.valid(active_checkpoint) and active_checkpoint.party[GUEST].progression == guest_duel_entry.progression and CoopValues.vector3(active_checkpoint.party[GUEST].position).distance_to(CoopValues.vector3(guest_duel_entry.position)) < 0.01, "checkpoint during a duel preserves the guest's pre-duel state")
	var escape_x: float = duel_arena.ARENA_CENTER.x + duel_arena.ARENA_HALF_SIZE.x + 3.0
	remote.actor.global_position = Vector3(escape_x, spawns[1].y + 0.12, duel_arena.ARENA_CENTER.y)
	await ticks(2)
	check(duel_arena.contains_arena(remote.actor.global_position) and remote.actor.global_position.distance_to(duel_arena.return_position(1)) < 0.5, "host returns a fighter that crosses the arena wall to their spawn")
	var drops_before_duel: int = host_game.world_items.pool.drops.size()
	for kill in 10:
		remote.health.invulnerability = 0.0
		remote.health.current = 1.0
		remote.health.damage(2.0, Vector3.ZERO, Damageable.HitKind.SOY)
		await ticks(1)
		if kill < 9:
			check(host_session.duel.phase == "round" and host_session.duel.scores == [kill + 1, 0], "defeat scores one kill and starts the next round")
			host_session.duel.countdown = 0.01
			await ticks(2)
	check(host_session.duel.phase == "complete" and host_session.duel.winner == HOST and host_session.duel.scores == [10, 0], "ten kills finish the duel")
	check(duel_arena.pad_for(host_game.player.global_position) < 0 and duel_arena.pad_for(remote.actor.global_position) < 0, "duelists are moved off their entry tiles after the match")
	check(host_game.world_items.pool.drops.size() == drops_before_duel, "duel defeat does not drop equipped items")
	check(host_game.player.motor.endurance.current == 40 and remote.actor.motor.endurance.current == 22 and remote.actor.motor.endurance.exhausted, "duel cleanup restores each original running reserve and exhaustion")
	check(remote.progression.progress.capture() == saved.party[GUEST].progression and remote.character_equipment.complete_set() == "bright_leaf" and remote.character_equipment.get_slot("combat_2").item.id == "soy_gun", "finishing restores each player's saved progression and equipment")
	var disconnect_pads: Array[Vector3] = host_game.world.duel_arena.pad_positions()
	host_game.player.relocate(Vector3(-40, 0.2, 0))
	remote.actor.relocate(Vector3(-42, 0.2, 0))
	host_session.duel._complete_remaining = 0.01
	await ticks(3)
	check(host_session.duel.phase == "idle", "leaving both pads makes the next duel available")
	host_game.player.relocate(disconnect_pads[0] + Vector3.UP * 0.26)
	remote.actor.relocate(disconnect_pads[1] + Vector3.UP * 0.26)
	await ticks(3)
	check(host_session.duel.phase == "entry", "the same pair can start another duel")
	host_session.duel.countdown = 0.01
	await ticks(3)
	var disconnect_entry: Dictionary = host_session.duel._fighters.saved_states[GUEST].duplicate(true)
	check(host_session.duel.phase == "fight", "rematch begins after its countdown")
	guest.leave()
	await ticks(3)
	check(host_session.duel.phase == "idle" and not host_session.roster.party.has(GUEST), "a player leaving during a duel aborts it cleanly")
	var guest_pad_exit: Vector3 = host_game.world.duel_arena.pad_exit_position(1)
	check(host_session.roster.saved_states[GUEST].progression == disconnect_entry.progression and host_session.roster.saved_states[GUEST].equipment == disconnect_entry.equipment and CoopValues.vector3(host_session.roster.saved_states[GUEST].position).distance_to(guest_pad_exit) < 0.01, "disconnect preserves pre-duel gear and releases the guest's entry tile")
	guest.join_room(HOST)
	await ticks(5)
	check(guest.playing and host_session.roster.party.has(GUEST), "a duelist can reconnect after the cancelled match")
	remote = host_session.roster.party[GUEST]
	check(remote.progression.progress.capture() == disconnect_entry.progression and remote.character_equipment.complete_set() == "bright_leaf" and remote.actor.position.distance_to(guest_pad_exit) < 0.5, "reconnect restores the guest's pre-duel character away from the entry tile")
	var rematch_pads: Array[Vector3] = host_game.world.duel_arena.pad_positions()
	host_game.player.relocate(rematch_pads[0] + Vector3.UP * 0.26)
	remote.actor.relocate(rematch_pads[1] + Vector3.UP * 0.26)
	await ticks(3)
	check(host_session.duel.phase == "entry", "a new pair can reserve the arena after the aborted match releases its tiles")
	host_session.duel.countdown = 0.01
	await ticks(3)
	check(host_session.duel.phase == "fight", "the released arena starts a fresh match")
	var host_exit_entry: Dictionary = host_session.duel._fighters.saved_states[HOST].duplicate(true)
	var guest_exit_entry: Dictionary = host_session.duel._fighters.saved_states[GUEST].duplicate(true)
	var observer := PlaytestRoom.new()
	root.add_child(observer)
	observer.local_key = OBSERVER
	observer.local_name = "Observer"
	observer.peers[HOST] = {"name": "Host", "hosting": true, "busy": true}
	host.peers[OBSERVER] = {"name": "Observer", "hosting": false, "busy": false}
	host.send_packet = func(key: String, data: Dictionary) -> void:
		var packet: Dictionary = {"type": "packet", "key": HOST, "data": JSON.parse_string(JSON.stringify(data))}
		if key == GUEST: guest.receive(packet)
		elif key == OBSERVER: observer.receive(packet)
	observer.send_packet = func(_key: String, data: Dictionary) -> void: host.receive({"type": "packet", "key": OBSERVER, "data": JSON.parse_string(JSON.stringify(data))})
	observer.join_room(HOST)
	await ticks(3)
	var spectator_member: CoopActor = host_session.roster.party.get(OBSERVER)
	check(spectator_member != null and host_session.duel.phase == "fight", "a third co-op player can join while the duel continues")
	if spectator_member != null:
		check(spectator_member.combat.targets.is_empty() and spectator_member.combat.gun.targets.is_empty() and not host_game.combat.targets.has(spectator_member.health) and not remote.combat.targets.has(spectator_member.health), "spectators cannot target or interfere with duelists")
		var spectator_progress: int = spectator_member.progression.progress.experience
		var host_duel_progress: int = host_game.progression.progress.experience
		var guest_duel_progress: int = remote.progression.progress.experience
		var reward_mob: TrainingMob
		for mob: TrainingMob in host_game.encounters.mob_nodes:
			if not mob is ArmoredSnail and mob.target.current > 0.0:
				reward_mob = mob
				break
		check(reward_mob != null, "spectator EXP test has a living world mob")
		if reward_mob != null:
			var world_exp_before: int = host_game.encounters.experience
			var killer_shot := SoyProjectile.new()
			killer_shot.shooter = spectator_member.actor
			killer_shot.owner_health = spectator_member.health
			killer_shot.velocity = Vector3.FORWARD * 60.0
			killer_shot.body_damage = 999.0
			killer_shot.head_damage = 999.0
			killer_shot.targets.append(reward_mob.target)
			killer_shot.position = reward_mob.global_position + Vector3.UP * 0.55 + Vector3.BACK * 1.5
			host_game.add_child(killer_shot)
			await ticks(3)
			check(host_game.encounters.experience == world_exp_before + 25 and host_game.progression.progress.experience == host_duel_progress and remote.progression.progress.experience == guest_duel_progress and spectator_member.progression.progress.experience == spectator_progress + 25, "spectator mob kill awards world EXP without changing either duelist")
		var arena_floor: float = host_game.world.duel_arena.spawn_positions()[0].y + 0.12
		host_game.player.relocate(Vector3(62, arena_floor, 47))
		remote.actor.relocate(Vector3(78, arena_floor, 47))
		spectator_member.actor.relocate(Vector3(70, arena_floor, 47))
		host_game.player.velocity = Vector3.ZERO
		remote.actor.velocity = Vector3.ZERO
		var target_health_before: float = remote.health.current
		var spectator_health_before: float = spectator_member.health.current
		var duel_gun: SoyGun = host_game.combat.gun
		duel_gun.shot_origin = host_game.player.global_position + Vector3.UP * duel_gun.tuning.muzzle_height
		duel_gun.shot_velocity = Vector3.RIGHT * duel_gun.tuning.bean_speed
		duel_gun._spawn(true)
		await ticks(24)
		check(remote.health.current < target_health_before and spectator_member.health.current == spectator_health_before, "duel shot passes through a spectator standing between fighters")
		spectator_member.actor.relocate(host_game.world.duel_arena.pad_positions()[0] + Vector3.UP * 0.26)
		host_session.duel.step(0.016)
		var competing_team: Array[String] = [HOST, OBSERVER]
		host_session.duel._begin_entry(competing_team)
		check(host_session.duel.phase == "fight" and host_session.duel.participants == [HOST, GUEST], "a competing team cannot replace the active duel")
		observer.leave()
		await ticks(3)
		var invalid_targets := false
		for target: Damageable in host_game.combat.targets:
			if not is_instance_valid(target): invalid_targets = true
		check(not host_session.roster.party.has(OBSERVER) and host_game.combat.targets.size() == 1 and host_game.combat.targets[0] == remote.health and not invalid_targets, "roster removal drops a departed spectator from duel targets")
		observer.join_room(HOST)
		await ticks(3)
		spectator_member = host_session.roster.party.get(OBSERVER)
		check(spectator_member != null and host_game.combat.targets.size() == 1 and host_game.combat.targets[0] == remote.health, "roster addition keeps active fighters on their current opponents")
	host_session.duel.session_ended()
	check(host_session.duel.phase == "idle" and host_game.progression.progress.capture() == host_exit_entry.progression and remote.progression.progress.capture() == guest_exit_entry.progression, "ending the host session restores both fighters from the active match")
	if spectator_member != null:
		var invalid_cleanup_targets := false
		for target: Damageable in host_game.combat.targets:
			if not is_instance_valid(target): invalid_cleanup_targets = true
		check(host_game.combat.targets.has(spectator_member.health) and remote.combat.targets.has(spectator_member.health) and not invalid_cleanup_targets, "match cleanup rebuilds targets from current players and releases departed references")
	store.remove_slot(0)
	DirAccess.remove_absolute(store.directory)
	host.leave()
	check(not guest.playing and not observer.playing, "host departure ends the session for all other players")
	for child in root.get_children(): child.queue_free()
	for frame in 4: await process_frame
	print("Co-op gameplay: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _game(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	viewport.add_child(game)
	var session := CoopSession.new()
	session.game = game
	session.room = room
	game.add_child(session)
	return session

func ticks(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame
