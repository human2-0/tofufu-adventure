extends SceneTree
## Real Cloud Realm equipment/shop and first-person rig; no persisted player edits.

const OUT: String = "/Users/mat-dwor/Documents/tofufu-adventure/.codex/visualizations/2026/10/08/celestial/"

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1440, 900)
	var game := preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await process_frame
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.set_physics_process(false)
	game.progression.progress.award_experience(CharacterProgress.threshold(5, true))
	for slot in CharacterEquipment.APPAREL_SLOTS:
		game.character_equipment.set_slot(slot, ItemStack.new(InventoryItem.apparel("celestial_" + slot), 1))
	game.player.position = game.world.cloud_realm.court.merchant.global_position + Vector3(0, 0.1, 1.5)
	game.camera.reset_follow()
	game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("celestial_sword"), 1))
	await create_timer(7.0).timeout
	await _capture("cloud-court-equipped")
	var interact := InputEventAction.new()
	interact.action = "pickup_weapon"
	interact.pressed = true
	game.merchant._unhandled_input(interact)
	await create_timer(0.2).timeout
	await _capture("nimbus-armory")
	game.merchant.window.close()
	game.player.position += Vector3(0, 0, 6.5)
	game.player.position = CloudTerrain.point(game.player.position.x, game.player.position.z, 0.1)
	var original_offset: Vector3 = game.camera.offset
	game.camera.offset = Vector3(0, 4.0, 4.0)
	game.camera.reset_follow()
	await create_timer(0.3).timeout
	await _capture("celestial-aura-closeup")
	game.camera.offset = original_offset
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	game.shooting_view.set_process_unhandled_input(false)
	game.camera.yaw = PI
	game.camera.pitch = -0.15
	await process_frame
	await process_frame
	game.shooting_view.set_process(false)
	game.combat.replica_view = true
	for id in ["celestial_sword", "celestial_staff", "soy_raygun"]:
		game.loadout.replica = false
		game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon(id), 1))
		game.hud.show_loadout(game.shooting_view._item_label(game.character_equipment.get_slot("combat_1")), "Unarmed", 1)
		for action in ["idle", "aim", "reload", "run", "cut", "guard", "punch"]:
			game.combat.active = action == "cut" and id != "soy_raygun"
			game.combat._elapsed = game.combat._attack_duration() * 0.5 if game.combat.active else 0.0
			game.combat.equipment.guarding = action == "guard" and id == "celestial_sword"
			game.combat.equipment._punch_time = 0.3 if action == "punch" else 0.0
			game.combat.gun.aiming = action == "aim"
			game.combat.gun.reload_remaining = 1.0 if action == "reload" else 0.0
			game.shooting_view.weapon_view.run_lowering = 1.0 if action == "run" else 0.0
			await create_timer(0.2).timeout
			await _capture("first-person-" + id + "-" + action)
	game.queue_free()
	await process_frame
	print("Celestial Cloud Realm and first-person previews saved in ", OUT)
	quit()

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
