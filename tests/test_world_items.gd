extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var game := preload("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await ticks(2)
	game.player.set_physics_process(false)
	game.player.position = Vector3.ZERO
	game.shooting_view.local_input.enabled = false
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	var gear: PlayerEquipment = game.combat.equipment
	var pool: WorldItemPool = game.world_items.pool
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.15)
	collision.shape = box
	wall.add_child(collision)
	game.add_child(wall)
	wall.position = Vector3(0, 1, -1.15)
	await ticks(2)
	gear.step(Vector2.UP, false, false, true, false, 1, 0.016)
	check(not gear.knife_owned and gear.dropped != null and pool.drops.has(gear.dropped.drop_id), "knife leaves inventory only after safe world placement")
	var knife: WorldItemDrop = gear.dropped
	await ticks(45)
	check(knife.global_position.z > -0.75, "swept drop body stays in front of thin wall")
	check(knife.global_position.y > 0.2, "drop rests above floor")
	game.player.position = Vector3(0, 0, -2)
	check(not game.world_items._pickup(knife.drop_id, game.combat), "pickup cannot reach through a wall")
	game.player.position = Vector3.ZERO
	var other_actor := CharacterBody3D.new()
	game.add_child(other_actor)
	var other := PlayerCombat.new()
	other.actor = other_actor
	game.add_child(other)
	var other_loadout := ActorLoadout.new()
	other_loadout.combat = other
	other_loadout.inventory = PlayerInventory.new()
	other_loadout.equipment = CharacterEquipment.new()
	other.add_child(other_loadout)
	game.world_items.register(other, other_loadout.inventory, other_loadout)
	other.equipment.knife_owned = false
	var knife_id := knife.drop_id
	check(game.world_items._pickup(knife_id, other), "another actor can collect the dropped knife")
	check(other.equipment.knife_owned and not gear.knife_owned, "ownership transfers without restoring the original owner")
	check(not game.world_items._pickup(knife_id, game.combat), "same item cannot be claimed twice")
	wall.queue_free()
	await ticks(2)
	gear.step(Vector2.UP, false, false, true, false, 2, 0.016)
	check(not gear.gun_owned and not game.combat.gun.selected, "selected gun can be dropped")
	gear.step(Vector2.UP, false, false, false, false, 2, 0.016)
	check(not game.combat.gun.selected, "unowned gun cannot be selected")
	var gun_id: int = gear.dropped.drop_id
	check(game.world_items._pickup(gun_id, game.combat) and gear.gun_owned, "gun can be recovered")
	game.character_equipment.set_slot("combat_2", ItemStack.new(InventoryItem.weapon("sotjet"), 1))
	game.loadout.select(2)
	game.combat.sotjet.milk = 37
	gear.step(Vector2.RIGHT, false, false, true, false, 2, 0.016)
	var jet_id: int = gear.dropped.drop_id
	check(not gear.sotjet_owned and pool.drops[jet_id].reserve == 37, "Sotjet retains its dropped reservoir")
	check(game.world_items._pickup(jet_id, other), "another actor receives dropped weapon into a combat slot")
	check(other.sotjet.milk == 37 and not pool.drops.has(jet_id), "pickup preserves reservoir and consumes world item")
	other.equipment._drop()
	var returned_id: int = other.equipment.dropped.drop_id
	check(game.world_items._pickup(returned_id, game.combat) and game.combat.sotjet.milk == 37, "weapon can be returned by dropping it")
	var north := pool.spawn("knife", 1, Vector3.ZERO, Vector2.UP)
	var east := pool.spawn("soy_gun", 1, Vector3.ZERO, Vector2.RIGHT)
	check(pool.focused(Vector3.ZERO, Vector2.UP) == north.drop_id, "focus chooses aimed item among nearby drops")
	check(pool.focused(Vector3.ZERO, Vector2.RIGHT) == east.drop_id, "turning focus selects a different item")
	var source: LocalPlayerInput = game.shooting_view.local_input
	var mayor: Vector3 = game.world.quest_npc.global_position
	game.player.global_position = mayor + Vector3(0, 0.1, 2.0)
	var nearby_bean := pool._create(900, "edamame", 1, 100.0, mayor + Vector3(1.2, 0.45, 1.7))
	source.enabled = true
	source._pointer_aim = false
	source._aim = Vector2.RIGHT
	await ticks(2)
	game.world_items._process(0.0)
	game.quest_giver._process(0.0)
	check(game.world_items.focused_id == nearby_bean.drop_id and source.pickup_target == nearby_bean.drop_id, "aiming at a bean beside Mayor Mame selects the bean")
	check(not game.quest_giver._prompt.visible, "Mayor Mame does not claim the bean's interaction prompt")
	source._pointer_aim = true
	var focus_camera: Camera3D = game.get_viewport().get_camera_3d()
	var bean_at := nearby_bean.global_position + Vector3.UP * 0.45
	var mayor_at := mayor + Vector3(0, 1.5, 0.65)
	var bean_pointer := focus_camera.unproject_position(bean_at)
	var mayor_pointer := focus_camera.unproject_position(mayor_at)
	check(game.world_items._focus_score(bean_at, game.player.global_position, source, focus_camera, bean_pointer) < game.world_items._focus_score(mayor_at, game.player.global_position, source, focus_camera, bean_pointer), "mouse over bean scores bean ahead of NPC")
	check(game.world_items._focus_score(mayor_at, game.player.global_position, source, focus_camera, mayor_pointer) < game.world_items._focus_score(bean_at, game.player.global_position, source, focus_camera, mayor_pointer), "mouse over NPC scores NPC ahead of bean")
	source._pointer_aim = false
	var interact := InputEventAction.new()
	interact.action = "pickup_weapon"
	interact.pressed = true
	game.quest_giver._unhandled_input(interact)
	check(not game.quest_giver.window.visible, "bean focus does not open Mayor Mame dialogue")
	source._aim = Vector2.UP
	game.world_items._process(0.0)
	game.quest_giver._process(0.0)
	check(game.world_items.focused_kind == "quest" and source.pickup_target == 0, "aiming back at Mayor Mame selects dialogue")
	check(game.quest_giver._prompt.visible, "selected NPC shows its interaction prompt")
	game.quest_giver._unhandled_input(interact)
	check(game.quest_giver.window.visible, "selected NPC opens dialogue with the shared key")
	game.quest_giver.window.close()
	source.enabled = false
	pool.remove(nearby_bean.drop_id)
	game.player.global_position = Vector3.ZERO
	game.inventory.add_item(InventoryItem.create_edamame(), 15)
	check(game.world_items.drop_stack(game.combat, game.inventory, game.character_equipment, "inventory", 0), "bag stack can be dropped")
	check(game.inventory.count_item("edamame") == 0, "bag drop removes the stack exactly once")
	var stack_drop: WorldItemDrop
	for drop: WorldItemDrop in pool.drops.values():
		if drop.item_id == "edamame": stack_drop = drop
	for child: Node in stack_drop.get_children():
		if child is Sprite3D:
			var sprite := child as Sprite3D
			check(sprite.pixel_size * maxf(sprite.texture.get_width(), sprite.texture.get_height()) <= 0.55, "dropped bean stack uses compact world art")
	for backpack_id in ["factory_backpack", "traveler_backpack"]:
		var backpack_drop := WorldItemDrop.new()
		backpack_drop.item_id = backpack_id
		WorldItemVisuals.build(backpack_drop)
		for child: Node in backpack_drop.get_children():
			if child is Sprite3D:
				var sprite := child as Sprite3D
				check(sprite.pixel_size * maxf(sprite.texture.get_width(), sprite.texture.get_height()) <= 0.7, "%s ground art is backpack-sized" % backpack_id)
		backpack_drop.free()
	var apparel_ids: Array[String] = ["bright_leaf_helmet", "bright_leaf_armor", "bright_leaf_legs", "bright_leaf_boots", "dark_leaf_helmet", "dark_leaf_armor", "dark_leaf_legs", "dark_leaf_boots"]
	var apparel_rows: Array = []
	for index in apparel_ids.size():
		var apparel_id := apparel_ids[index]
		var apparel_drop := WorldItemDrop.new()
		apparel_drop.item_id = apparel_id
		WorldItemVisuals.build(apparel_drop)
		var apparel_sprite: Sprite3D
		for child: Node in apparel_drop.get_children():
			if child is Sprite3D: apparel_sprite = child
		check(apparel_sprite != null, "%s has ground art" % apparel_id)
		if apparel_sprite != null:
			var item := InventoryItem.apparel(apparel_id)
			var world_span := apparel_sprite.pixel_size * maxf(float(apparel_sprite.texture.get_width()), float(apparel_sprite.texture.get_height()))
			check(world_span <= 0.45 and world_span >= 0.3, "%s ground art is sized for a single apparel piece" % apparel_id)
			var pixels := apparel_sprite.texture.get_image()
			if pixels.is_compressed(): pixels.decompress()
			var used := pixels.get_used_rect()
			var alpha_bottom := used.position.y + used.size.y - 1
			var floor_y := (pixels.get_height() * 0.5 - alpha_bottom + apparel_sprite.offset.y) * apparel_sprite.pixel_size
			check(is_equal_approx(floor_y, -WorldItemDrop.RADIUS), "%s rests on the ground" % apparel_id)
		apparel_rows.append([900 + index, apparel_id, 1, 100.0, 0.0, 0.4, 0.0])
		apparel_drop.free()
	check(WorldProtocol.world_items(apparel_rows), "apparel drops pass the co-op world item schema")
	for slot in PlayerInventory.CAPACITY: game.inventory.set_slot(slot, ItemStack.new(InventoryItem.create_edamame(), 100))
	check(not game.world_items._pickup(stack_drop.drop_id, game.combat) and stack_drop.count == 15, "full bag leaves world stack intact")
	game.inventory.get_slot(0).count = 99
	check(game.world_items._pickup(stack_drop.drop_id, game.combat) and stack_drop.count == 14, "partial pickup preserves the remainder on the ground")
	var save := AdventureSnapshot.capture(game, "Drops", 0)
	check(SaveStore.valid(save) and WorldProtocol.world_items(save.world_items), "drop snapshot passes save and network schemas")
	var apparel_save := save.duplicate(true)
	apparel_save.world_items = apparel_rows
	check(SaveStore.valid(apparel_save), "save schema accepts dropped apparel for either set")
	var saved_drop_count := pool.drops.size()
	pool.restore([])
	AdventureSnapshot.restore(game, save)
	check(pool.drops.size() == saved_drop_count and not gear.knife_owned, "save restores world items independently of weapon ownership")
	var legacy := save.duplicate(true)
	legacy.erase("world_items")
	legacy.dropped_position = [0, 0, -1]
	AdventureSnapshot.restore(game, legacy)
	check(pool.drops.size() == 1 and pool.drops.values()[0].item_id == "knife", "legacy knife save migrates into shared pool")
	AdventureSnapshot.restore(game, save)
	var bad: Array = save.world_items.duplicate(true)
	bad[0][1] = "arbitrary_resource_path"
	check(not WorldProtocol.world_items(bad), "unknown network item identifiers are rejected")
	if "--preview" in OS.get_cmdline_user_args():
		other.queue_free()
		other_actor.queue_free()
		game.world_items.set_process(false)
		game.player.position = Vector3(0, 0, 1)
		pool.restore([[20, "knife", 1, 100, -0.9, 0.45, -0.2], [21, "soy_gun", 1, 100, 0, 0.45, -0.7], [22, "sotjet", 1, 37, 0.9, 0.45, -0.2]])
		pool.drops[21].set_focus(true, "[E] Pick up Soybean gun")
		game.camera.offset *= 0.45
		await ticks(30)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-world-items.png")
		pool.restore([[23, "traveler_backpack", 1, 100, 0, 0.45, -0.7]])
		await ticks(10)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-ground-backpack.png")
		game.player.global_position = mayor + Vector3(0, 0.1, 2.0)
		pool.restore([[900, "edamame", 1, 100, mayor.x + 1.2, mayor.y + 0.45, mayor.z + 1.7]])
		game.inventory.clear()
		game.world_items.set_process(true)
		source.enabled = true
		source._pointer_aim = false
		source._aim = Vector2.RIGHT
		await ticks(30)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-interaction-bean.png")
		source._aim = Vector2.UP
		await ticks(4)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-interaction-mayor.png")
	game.queue_free()
	await process_frame
	print("World items: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
