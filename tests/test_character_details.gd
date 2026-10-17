extends SceneTree
## Character hub, real authority recovery, equipment math and bounded migrations.
var failures: int = 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.device = 16
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func _run() -> void:
	var progress := CharacterProgress.new()
	progress.record_journey("trail", 499)
	check(progress.journey.rank("trail") == 0, "walking medal waits for all 500 metres")
	progress.record_journey("trail", 1)
	check(is_equal_approx(progress.walk_multiplier(), 1.03), "first walking medal improves speed without EXP")
	progress.record_journey("care", 150)
	check(is_equal_approx(progress.journey.recovery_multiplier(), 1.08), "care medal grants bounded recovery")
	progress.record_journey("rhythm", 50)
	check(is_equal_approx(progress.attack_multiplier(), 1.04), "confirmed practice improves attack rhythm")
	var saved := progress.capture()
	var restored := CharacterProgress.new()
	restored.restore(JSON.parse_string(JSON.stringify(saved)))
	check(restored.journey.totals == progress.journey.totals, "personal milestones survive JSON save")
	for track in JourneyPractice.TRACKS:
		progress.record_journey(track, 1000000)
		check(progress.journey.rank(track) == 5, "milestone progression caps at five")
		for bad: Variant in [-1, 0.5, INF, NAN, "150", JourneyPractice.threshold(track, 5) + 1]:
			var malformed := saved.duplicate(true)
			malformed.journey[track] = bad
			check(not SaveStore.progression(malformed) and not ExplorationProtocol.progression(malformed), "save and wire reject malformed mastery")
	var legacy := saved.duplicate(true)
	legacy.version = 2
	legacy.erase("journey")
	restored.restore(legacy)
	check(restored.journey.rank("trail") == 0 and SaveStore.progression(legacy) and ExplorationProtocol.progression(legacy), "old character records start with fresh milestones")
	var game: AdventureGame = preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	await process_frame
	game.set_process_unhandled_input(false)
	key(KEY_I)
	await process_frame
	var sheet: CharacterSheet
	for child in game.inventory_window.get_children():
		if child is CharacterSheet: sheet = child
	check(sheet != null and sheet.visible and game.inventory_window.visible, "I opens character hub even without solo root input")
	check(not game.shooting_view.local_input.enabled and not game.chat.view.available, "hub blocks gameplay and chat")
	check(sheet.bag_button.has_focus(), "controller opens on an actionable tab button")
	sheet.bag_requested.emit()
	check(not sheet.visible and game.inventory_window._backpack_dock.visible, "bag tab retains equipment and inventory")
	game.inventory_window.character_requested.emit()
	check(sheet.visible and not game.inventory_window._backpack_dock.visible, "character tab restores stats")
	game.progression.progress.award_experience(100)
	sheet.stat_point_allocated.emit("defence")
	check(game.progression.progress.stat_points == 0 and game.progression.progress.stats.defence == 1, "sheet spends through existing allocation path")
	game.progression.progress.restore({})
	game.health.current = 40
	game.healing.active_heal_remaining = 100
	game.healing.active_heal_rate = 100
	game.healing.step(1)
	check(game.progression.progress.journey.totals.care == 60, "only actual missing HP restored earns care")
	game.healing.active_heal_remaining = 100
	game.healing.step(1)
	check(game.progression.progress.journey.totals.care == 60, "full-health consumables give no care progress")
	game.combat.replica_view = true
	game.progression.care._recovered(100)
	check(game.progression.progress.journey.totals.care == 60, "replicas cannot award care milestones")
	game.combat.replica_view = false
	game.progression.care.enabled = false
	game.progression.care._recovered(100)
	check(game.progression.progress.journey.totals.care == 60, "equalized arenas cannot earn permanent care")
	game.progression.care.enabled = true
	game.progression.progress.award_experience(CharacterProgress.threshold(20, true))
	for slot in CharacterEquipment.APPAREL_SLOTS: game.character_equipment.set_slot(slot, ItemStack.new(InventoryItem.apparel("dark_leaf_" + slot)))
	var data := CharacterDetailsData.build(game)
	check(is_equal_approx(data.rows[2].total, game.player.tuning.walk_speed * game.player.motor.walk_multiplier), "sheet walking speed matches actual motor with outfit")
	check(data.rows[2].gear > 0 and data.rows[6].gear > 0, "equipment segments display real walk and protection bonuses")
	game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("nori_katana")))
	game.loadout.select(1)
	game.character_equipment.get_slot("combat_1").enhanced = true
	game.loadout.refresh(false)
	data = CharacterDetailsData.build(game)
	check(is_equal_approx(data.rows[5].total, game.combat.tuning.light_damage * game.combat.sword_damage_multiplier * 1.2), "held damage includes per-instance enhancement and outfit")
	check(is_equal_approx(data.rows[3].total / 100, game.combat.melee_speed()), "cadence includes weapon and outfit modifiers")
	for slot in CharacterEquipment.APPAREL_SLOTS: game.character_equipment.set_slot(slot, ItemStack.new(InventoryItem.apparel("celestial_" + slot)))
	var jet := ItemStack.new(InventoryItem.weapon("sotjet"))
	jet.enhanced = true
	game.character_equipment.set_slot("combat_1", jet)
	var jet_data := CharacterDetailsData.build(game)
	var jet_dps := game.combat.sotjet.flow.tuning.damage_per_second * game.combat.sotjet.flow.damage_multiplier * game.combat.sotjet.flow.enhancement_multiplier * game.combat.sotjet.flow.attack_cadence_multiplier
	check(is_equal_approx(jet_data.rows[5].total, jet_dps), "stream DPS includes equipment damage and stream cadence")
	sheet.present(data)
	check(sheet.stat_rows[0].value.text == "%d HP" % ceili(data.rows[0].total), "maximum health always rounds upward to a whole number")
	check(sheet.stat_rows[1].value.text == "%d SP" % ceili(data.rows[1].total), "maximum stamina always rounds upward to a whole number")
	check(sheet.stat_rows[5].value.text == "%d DMG" % ceili(data.rows[5].total), "damage rounds upward without changing runtime damage")
	check(sheet.stat_rows[2].value.text == String.num(data.rows[2].total, 2) + " m/s", "walking speed keeps its precise readout")
	check(sheet.stat_rows[3].value.text == String.num(data.rows[3].total, 2) + " %", "attack pace keeps its precise readout")
	sheet.stat_rows[6].button.focus_entered.emit()
	check(sheet.selected_stat == 6 and sheet.inspector_title.text == "Damage reduction", "controller focus updates the same persistent inspector as hover")
	sheet.stat_rows[2].button.mouse_entered.emit()
	check(sheet.selected_stat == 2, "mouse hover selects stat details")
	sheet.select_page(1)
	check(sheet.pages[1].visible and not sheet.pages[0].visible, "training is a distinct page")
	check(sheet.skills.sword.button.tooltip_text.contains("Rank") and sheet.skills.sword.benefit.text.contains(String.num(CharacterProgress.TUNING.weapon_damage * 100, 2) + "%"), "investments preview the next rank and actual tuning")
	check(sheet.skills.magic.button.disabled, "reserved magic cannot waste a point")
	TranslationServer.set_locale("pl")
	sheet.present(data)
	check(sheet.heading.text.contains("MÓJ TOFUFU") and sheet.heading.text.contains("Poziom 20"), "character heading uses Polish")
	check(sheet.stat_rows[0].title.text == "Maksymalne zdrowie", "attribute labels use Polish")
	check(sheet.inspector_title.text == "Prędkość marszu" and sheet.inspector_sources[1].text.begins_with("+"), "selected stat has a translated inspector with explicit signed contributions")
	check(sheet.milestones[0].title.text.contains("Odkrywca szlaków"), "mastery titles use Polish")
	check(sheet.skills.sword.benefit.text.contains("Dalej:") and sheet.page_buttons[1].tr(sheet.page_buttons[1].text) == "Trening i troska", "training benefits and page tabs translate live")
	check(sheet.gear.text.contains("W ręku:") and not sheet.gear.text.contains("Held:"), "equipment summary translates at presentation")
	sheet.select_page(0)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	for locale in ["pl", "en"]:
		TranslationServer.set_locale(locale)
		for stat in 9:
			sheet.inspect_stat(stat)
			for frame in 4: await process_frame
			_check_fit(sheet, locale)
		sheet.select_page(1)
		for frame in 4: await process_frame
		_check_fit(sheet, locale)
		sheet.select_page(0)
	TranslationServer.set_locale("en")
	check(sheet.heading.text.contains("MY TOFUFU") and sheet.stat_rows[0].title.text == "Maximum health", "live locale switch restores English without reopening")
	key(KEY_B)
	check(game.inventory_window.visible and not sheet.visible and game.inventory_window._backpack_dock.visible, "B switches player info to inventory without releasing gameplay")
	check(not game.shooting_view.local_input.enabled, "switching pages keeps gameplay blocked")
	key(KEY_B)
	check(not game.inventory_window.visible and game.shooting_view.local_input.enabled, "B closes inventory and restores movement")
	var select := InputEventJoypadButton.new()
	select.device = 16
	select.button_index = JOY_BUTTON_BACK
	select.pressed = true
	root.push_input(select)
	await process_frame
	check(game.inventory_window.visible and sheet.visible, "controller Select opens character hub")
	select = select.duplicate()
	select.pressed = false
	root.push_input(select)
	key(KEY_ESCAPE)
	check(not game.inventory_window.visible, "Escape closes before pause")
	# Exercise actual capsule movement in an unobstructed, isolated physics world.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.5
	viewport.add_child(floor_body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(100, 1, 100)
	collider.shape = shape
	floor_body.add_child(collider)
	var walker: Player = preload("res://game/player/player.tscn").instantiate()
	var source := CoopTestInput.new()
	walker.add_child(source)
	walker.command_source = source
	walker.position.y = 0.1
	viewport.add_child(walker)
	var host := CoopActor.new()
	host.actor = walker
	host.authority = true
	viewport.add_child(host)
	for frame in 20: await physics_frame
	source.move = Vector2.RIGHT
	for frame in 240: await physics_frame
	source.move = Vector2.ZERO
	var travelled: int = host.progression.progress.journey.totals.trail
	check(travelled >= 10, "collision-resolved walking earns permanent trail progress")
	walker.transport_active = true
	source.move = Vector2.RIGHT
	for frame in 20: await physics_frame
	source.move = Vector2.ZERO
	check(host.progression.progress.journey.totals.trail == travelled, "transport cannot earn walking progress")
	viewport.queue_free()
	var remote_actor: Player = preload("res://game/player/player.tscn").instantiate()
	root.add_child(remote_actor)
	var replica := CoopActor.new()
	replica.actor = remote_actor
	replica.authority = false
	root.add_child(replica)
	replica.progression.progress.restore(game.progression.progress.capture())
	var care_before: int = replica.progression.progress.journey.totals.care
	replica.progression.care._recovered(100)
	check(replica.progression.progress.journey.totals.care == care_before, "actual co-op replica never earns care")
	check(ExplorationProtocol.actor(replica.capture()), "milestones use validated co-op actor snapshots")
	replica.queue_free()
	remote_actor.queue_free()
	game.queue_free()
	await process_frame
	print("Character details: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _check_fit(sheet: CharacterSheet, locale: String) -> void:
	for page in sheet.pages:
		if not page.visible: continue
		for child in page.get_children():
			if child is ScrollContainer:
				var bar: VScrollBar = child.get_v_scroll_bar()
				check(bar.max_value <= bar.page + 1, "full-size character pages need no scrolling in " + locale)
