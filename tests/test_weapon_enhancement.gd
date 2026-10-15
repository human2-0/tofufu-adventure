extends SceneTree
## Chunk probability, atomic use, weapon identity, damage, reload, saves and replicas.
var failures: int = 0
const HOST := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const GUEST := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	_rules()
	await _confirmation()
	var game: Node3D = preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await process_frame
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.relocate(Vector3(8, 0.1, 8))
	await physics_frame
	var bag: PlayerInventory = game.inventory
	var gear: CharacterEquipment = game.character_equipment
	bag.set_slot(0, ItemStack.new(MagicalTofufu.create(), 3))
	var knife := gear.get_slot("combat_1")
	var gun := gear.get_slot("combat_2")
	check(InventoryTransfer.apply(bag, gear, "inventory", 0, "equipment", "combat_2"), "chunk applies onto an equipped weapon")
	check(gun.enhanced and not knife.enhanced and bag.get_slot(0).count == 2, "one chunk consumed and only chosen weapon upgraded")
	check(not InventoryTransfer.apply(bag, gear, "inventory", 0, "equipment", "combat_2") and bag.get_slot(0).count == 2, "second application consumes nothing")
	check(not InventoryTransfer.apply(bag, gear, "inventory", 0, "equipment", "backpack"), "non-weapon cannot be enhanced")
	game.loadout.select(2)
	check(game.combat.gun.magazine_capacity == 14 and game.combat.gun.magazine == 9, "+5 capacity does not mint ammunition")
	game.combat.gun.reload()
	game.combat.gun.step(false, false, Vector2.RIGHT, Vector3(12, 1, 8), 2.01)
	check(game.combat.gun.magazine == 14, "reload fills the enhanced magazine")
	check(is_equal_approx(game.combat.gun.enhancement_multiplier, 1.2), "gun damage gets twenty percent bonus")
	game.hud.show_gun_status(14, 0, 0, true, 14)
	check("14 / 14" in game.hud._charge_text.text, "HUD shows effective capacity")
	var combat_state := CombatState.capture(game.combat)
	check(ExplorationProtocol.combat(combat_state), "enhanced fourteen-round combat snapshot validates")
	combat_state.gun_magazine = 15
	check(not ExplorationProtocol.combat(combat_state), "fifteen-round snapshot rejected")
	combat_state.gun_magazine = 14
	combat_state.enhanced = false
	check(not ExplorationProtocol.combat(combat_state), "ordinary gun cannot carry fourteen rounds")
	game.loadout.select(1)
	check(game.combat.gun.magazine_capacity == 9 and not game.combat.equipment.weapon_enhanced, "switching removes selected weapon bonus")
	check(InventoryTransfer.apply(bag, gear, "inventory", 0, "equipment", "combat_1"), "melee can also be enhanced")
	var body := StaticBody3D.new()
	game.add_child(body)
	var target := Damageable.new()
	target.body = body
	target.maximum = 1000
	body.add_child(target)
	game.combat.attack_style = KnifeAttack.Style.SLASH
	var expected: float = game.combat._melee_damage() * game.combat.sword_damage_multiplier * 1.2
	var before := target.current
	MeleeSweep.damage(game.combat, target)
	check(is_equal_approx(before - target.current, expected), "actual melee hit applies enhanced power")
	game.combat.reset()
	body.queue_free()
	check(knife.duplicate_stack().enhanced and ItemStack.restore(knife.capture()).enhanced, "duplicate and save retain per-item enhancement")
	check(not ItemStack.restore({"id": "knife", "count": 1}).enhanced, "legacy weapon defaults to ordinary")
	check(ItemStack.restore({"id": "apple", "count": 1, "enhanced": true}) == null, "non-weapon enhancement rejected")
	check(ItemStack.restore({"id": "knife", "count": 1, "enhanced": 1}) == null, "non-boolean enhancement rejected")
	var chest := ChestInventory.new()
	bag.set_slot(2, gun.duplicate_stack())
	check(ChestTransfer.apply(bag, chest, "inventory", 2, "chest", 0), "enhanced weapon enters storage")
	var restored_chest := ChestInventory.new()
	restored_chest.restore(chest.capture())
	check(restored_chest.get_slot(0).enhanced, "storage save keeps the upgrade")
	bag.set_slot(2, null)
	check(ChestTransfer.quick_move(bag, restored_chest, "chest", 0), "upgraded weapon returns from storage")
	# Remove the test duplicate before testing real world-drop ownership.
	for index in bag.capacity:
		if bag.get_slot(index) != null and bag.get_slot(index).item.id == "soy_gun": bag.set_slot(index, null)
	game.loadout.select(2)
	check(game.world_items.drop_stack(game.combat, bag, gear, "equipment", "combat_2"), "upgraded weapon can be physically dropped")
	var dropped: WorldItemDrop
	for drop: WorldItemDrop in game.world_items.pool.drops.values():
		if drop.item_id == "soy_gun": dropped = drop
	check(dropped != null and dropped.enhanced, "world drop retains enhancement")
	var rows: Array = game.world_items.pool.capture()
	check(WorldProtocol.world_items(rows) and SaveStore._world_items(rows), "live and save drop schemas accept upgraded weapon")
	game.world_items.pool.restore(JSON.parse_string(JSON.stringify(rows)))
	check(dropped.enhanced and game.world_items._pickup(dropped.drop_id, game.combat), "restored drop picked up with upgrade intact")
	check(gear.get_slot("combat_2").enhanced, "pickup restores enhanced item instance")
	var snapshot := AdventureSnapshot.capture(game, "Magic test", 0)
	check(SaveStore.valid(snapshot), "complete adventure save accepts upgrade")
	gear.get_slot("combat_2").enhanced = false
	AdventureSnapshot.restore(game, snapshot)
	check(gear.get_slot("combat_2").enhanced, "complete adventure restore retains enhancement")
	var count_before: int = game.world_items.pool.drops.size()
	game.world_items.magic_roll = func() -> float: return 0.001
	check(not MagicalMobLoot.drop(game.world_items, Vector3(10, 0, 10)), "exact probability boundary does not drop")
	game.world_items.magic_roll = func() -> float: return 0.000999
	check(MagicalMobLoot.drop(game.world_items, Vector3(10, 0, 10)), "roll below 0.1 percent drops one chunk")
	check(game.world_items.pool.drops.size() == count_before + 1, "rare roll creates exactly one shared drop")
	game.world_items.pool.authoritative = false
	game.world_items.magic_roll = func() -> float: return 0.0
	check(not MagicalMobLoot.drop(game.world_items, Vector3(10, 0, 10)), "replica never rolls loot")
	_soyjet(game)
	game.queue_free()
	await process_frame
	await _coop()
	print("Weapon enhancement: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _confirmation() -> void:
	GamePreferences.install_translations(self)
	TranslationServer.set_locale("en")
	var window := InventoryWindow.new()
	window.inventory = PlayerInventory.new()
	window.equipment = CharacterEquipment.new()
	window.inventory.set_slot(0, ItemStack.new(MagicalTofufu.create(), 2))
	window.inventory.set_slot(1, ItemStack.new(InventoryItem.weapon("knife")))
	window.execute_transfer("inventory", 0, "inventory", 1)
	check(not window.inventory.get_slot(1).enhanced and window.inventory.get_slot(0).count == 2, "unready window cannot bypass enhancement confirmation")
	root.add_child(window)
	window.open()
	window.execute_transfer("inventory", 0, "inventory", 1)
	var dialog := window.enhancement_confirmation
	check(dialog.visible and not window.inventory.get_slot(1).enhanced and window.inventory.get_slot(0).count == 2, "application opens confirmation without consuming material")
	check("+20%" in dialog.dialog_text and "once" in dialog.dialog_text, "confirmation explains permanent power and one-use limit")
	TranslationServer.set_locale("pl")
	await process_frame
	check(dialog.title == "Wzmocnić broń?" and "Nożyk" in dialog.dialog_text, "open dialog switches to Polish with translated weapon name")
	TranslationServer.set_locale("en")
	await process_frame
	check(dialog.title == "Enhance weapon?", "open dialog switches back to English")
	dialog.canceled.emit()
	check(not dialog.visible and window.inventory.get_slot(0).count == 2 and not window.inventory.get_slot(1).enhanced, "cancel consumes nothing")
	window.execute_transfer("inventory", 0, "inventory", 1)
	window.inventory.set_slot(1, ItemStack.new(InventoryItem.weapon("knife")))
	dialog.confirmed.emit()
	check(not window.inventory.get_slot(1).enhanced and window.inventory.get_slot(0).count == 2, "confirmation refuses a replaced weapon instance")
	window.execute_transfer("inventory", 0, "inventory", 1)
	dialog.confirmed.emit()
	check(window.inventory.get_slot(1).enhanced and window.inventory.get_slot(0).count == 1, "approval permanently enhances exactly the selected weapon")
	dialog.confirmed.emit()
	check(window.inventory.get_slot(0).count == 1, "duplicate confirmation cannot consume another chunk")
	window.inventory.set_slot(2, ItemStack.new(InventoryItem.weapon("sotjet")))
	window.execute_transfer("inventory", 0, "inventory", 2)
	check("+25%" in dialog.dialog_text, "Soyjet confirmation explains longer firing time")
	window.close()
	check(not dialog.visible and window.inventory.get_slot(0).count == 1, "closing inventory cancels pending enhancement")
	window.queue_free()
	await process_frame

func _soyjet(game: Node3D) -> void:
	var weapon := ItemStack.new(InventoryItem.weapon("sotjet"))
	weapon.enhanced = true
	game.character_equipment.set_slot("combat_2", weapon)
	game.loadout.select(2)
	var jet: Sotjet = game.combat.sotjet
	check(is_equal_approx(jet.consumption_multiplier, 0.8) and is_equal_approx(jet.flow.enhancement_multiplier, 1.2), "enhanced Soyjet gets power and duration bonuses")
	jet.milk = 100
	for index in 100: jet.step(true, false, Vector2.RIGHT, game.player.position + Vector3(10, 1, 0), 0.05)
	check(is_equal_approx(jet.milk, 20.0), "enhanced Soyjet retains twenty percent reserve after five seconds")
	for index in 25: jet.step(true, false, Vector2.RIGHT, game.player.position + Vector3(10, 1, 0), 0.05)
	check(jet.milk < 0.81, "enhanced Soyjet fires for 6.25 seconds until empty")
	game.loadout.select(1)
	check(is_equal_approx(jet.consumption_multiplier, 1.0), "switching away removes enhanced Soyjet consumption modifier")

func _rules() -> void:
	var bag := PlayerInventory.new()
	var gear := CharacterEquipment.new()
	var ids: Array[String] = ["knife", "soy_gun", "sotjet", "sproutwood_staff", "edamame_sword", "nori_katana", "celestial_sword", "celestial_staff", "soy_raygun"]
	for id in ids:
		bag.set_slot(0, ItemStack.new(MagicalTofufu.create(), 2))
		bag.set_slot(1, ItemStack.new(InventoryItem.weapon(id)))
		bag.set_slot(2, ItemStack.new(InventoryItem.weapon(id)))
		check(InventoryTransfer.apply(bag, gear, "inventory", 0, "inventory", 1), "%s can be enhanced while in bag" % id)
		check(bag.get_slot(1).enhanced and not bag.get_slot(2).enhanced, "%s upgrade is independent of an identical weapon" % id)
		check(not InventoryTransfer.apply(bag, gear, "inventory", 0, "inventory", 1) and bag.get_slot(0).count == 1, "%s refuses repeat enhancement without consuming chunk" % id)
		check(InventoryProtocol.valid({"inventory": bag.capture()}) and InventorySaveValidation.valid({"inventory": bag.capture()}), "%s item records validate" % id)
	bag.set_slot(0, ItemStack.new(MagicalTofufu.create(), 1))
	bag.set_slot(1, ItemStack.new(InventoryItem.weapon("knife")))
	check(InventoryTransfer.apply(bag, gear, "inventory", 0, "inventory", 1) and bag.get_slot(0) == null, "last chunk frees its source slot atomically")
	var malformed := {"inventory": [{"id": "apple", "count": 1, "enhanced": true}]}
	check(not InventoryProtocol.valid(malformed) and not InventorySaveValidation.valid(malformed), "enhanced consumable rejected by actor/save validators")
	var drop_rows: Array = [[1, "knife", 1, 100.0, 0, 0, 0, [], {"enhanced": true, "bay": 0, "owner": "solo"}]]
	check(WorldProtocol.world_items(drop_rows) and SaveStore._world_items(drop_rows), "enhancement coexists with protected barn display metadata")
	drop_rows[0][1] = "apple"
	check(not WorldProtocol.world_items(drop_rows) and not SaveStore._world_items(drop_rows), "enhanced non-weapon world drop rejected")

func _coop() -> void:
	var host := PlaytestRoom.new()
	var guest := PlaytestRoom.new()
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
	var authority := _game(host)
	var client := _game(guest)
	await ticks(15)
	var member: CoopActor = authority.roster.party[GUEST]
	var replica: CoopActor = client.roster.party[GUEST]
	member.inventory.set_slot(0, ItemStack.new(MagicalTofufu.create(), 2))
	member.loadout.select(2)
	await ticks(8)
	client.game.inventory_window.execute_transfer("inventory", 0, "equipment", "combat_2")
	check(not replica.character_equipment.get_slot("combat_2").enhanced, "unconfirmed client intent does not mutate local weapon")
	client.game.inventory_window.enhancement_confirmation.confirmed.emit()
	await ticks(12)
	check(member.character_equipment.get_slot("combat_2").enhanced and replica.character_equipment.get_slot("combat_2").enhanced, "authority enhancement crosses actual JSON transport")
	check(member.inventory.get_slot(0).count == 1 and replica.inventory.get_slot(0).count == 1, "chunk consumption synchronizes to guest")
	check(replica.combat.equipment.weapon_enhanced and replica.combat.gun.magazine_capacity == 14, "replica presents upgraded weapon and capacity")
	authority.inventory_sync._packet(GUEST, {"type": "inventory_transfer", "sequence": 1, "src": "inventory", "src_id": 0, "dst": "equipment", "dst_id": "combat_1"})
	await ticks(3)
	check(not member.character_equipment.get_slot("combat_1").enhanced, "replayed enhancement intent is rejected")
	client.game.inventory_window.execute_transfer("inventory", 0, "equipment", "combat_2")
	await ticks(3)
	check(member.inventory.get_slot(0).count == 1, "second host request cannot consume another chunk")
	check(CoopCheckpoint.valid(CoopCheckpoint.capture(authority)), "checkpoint accepts per-weapon upgrades")
	host.leave()
	for child in root.get_children(): child.queue_free()
	await ticks(3)

func _game(room: PlaytestRoom) -> CoopSession:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var game: Node3D = preload("res://game/app/adventure/main.tscn").instantiate()
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
