extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.weather.set_physics_process(false)
	for mob in game.encounters.mob_nodes: mob.set_physics_process(false)
	check(game.encounters.mob_nodes.size() == 59, "twelve archers appended after legacy roster")
	var quest := game.quest_giver.quest
	game.encounters.angel_defeated.emit(Vector3.ZERO)
	check(quest.god_count == 0, "kills before acceptance do not count")
	game.player.position = game.world.cloud_realm.godfufu.global_position + Vector3(0, 0, 2)
	await physics_frame
	game.camera.position = game.player.position + Vector3(0, 5, 8)
	game.camera.look_at(game.world.cloud_realm.godfufu.global_position + Vector3.UP)
	WorldInteractionFocus.select_focus(game.world_items, game.shooting_view.local_input)
	check(game.world_items.focused_kind == "god_quest", "Godfufu participates in the real interaction focus")
	game.god_hunt._action("accept")
	check(quest.god_status == QuestState.Status.IN_PROGRESS, "accept at Godfufu")
	game.encounters.mob_defeated.emit(Vector3.ZERO)
	check(quest.god_count == 0, "other mobs do not count")
	for i in 199: game.encounters.angel_defeated.emit(Vector3.ZERO)
	check(not quest.claim_god(), "cannot claim early")
	var saved := quest.capture()
	var restored := QuestState.new()
	restored.restore(saved)
	check(restored.god_count == 199 and GrandmaQuestProtocol.valid(saved), "hunt roundtrips through validated character schema")
	game.encounters.angel_defeated.emit(Vector3.ZERO)
	var before := game.progression.progress.experience
	game.god_hunt._action("claim")
	check(game.progression.progress.experience == before + 50000, "exact 50k experience")
	check(game.inventory.count_item("golden_tofu_chunk") == 10, "exact ten golden chunks")
	game.god_hunt._action("claim")
	check(game.progression.progress.experience == before + 50000 and game.inventory.count_item("golden_tofu_chunk") == 10, "reward cannot repeat")
	var legacy := saved.duplicate()
	legacy.erase("god_status")
	legacy.erase("god_count")
	check(GrandmaQuestProtocol.valid(legacy), "legacy quests still load")
	var invalid := saved.duplicate()
	invalid.god_count = 201
	check(not GrandmaQuestProtocol.valid(invalid), "out of range quest rejected")
	for i in range(43, 55):
		var archer := game.encounters.mob_nodes[i] as TofufuArcher
		check(archer != null and archer.target.maximum == 420, "level twenty archer health")
		check(is_equal_approx((archer._collider.shape as CapsuleShape3D).height, 1.8) and archer.shot_height == 1.2, "archer capsule and bow origin match tall sprite")
		archer.set_rain(true)
		check(archer.target.current == 420, "weather does not weaken archers")
		archer.set_rain(false)
		var at := archer.position
		check(absf(at.y - game.world.ground_point(at.x, at.z).y - 0.1) < 0.01, "spawn follows authored terrain")
		var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 5, at - Vector3.UP * 5, 1)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
		check(not hit.is_empty() and absf(hit.position.y - (at.y - 0.1)) < 0.03, "collision matches ground")
	var archer := game.encounters.mob_nodes[43] as TofufuArcher
	game.player.position = archer.position + Vector3.BACK * 6
	archer.quarry = game.player
	archer._choose_direction(0.01)
	check(archer._windup == 0.9, "readable bow telegraph")
	var locked := archer._sting_aim
	game.player.position.x += 3
	archer._choose_direction(0.91)
	check(archer.sting.active and archer.sting.velocity.normalized().distance_to(locked) < 0.01, "locked groat aim permits sidestepping")
	var world := CoopWorld.capture(game)
	check(WorldProtocol.valid(world), "expanded authoritative world validates")
	var before_exp := game.encounters.experience
	archer.target.damage(9999)
	check(game.encounters.experience == before_exp + 450, "grinding EXP per kill")
	check(not archer.sting.active and archer._respawn == 18, "death clears projectile and enables renewable hunt")
	for x in [-40.0, 0.0, 40.0]:
		check(game.world.jungle.point(x, 340).distance_to(game.world.groatfields.point(x, 340)) < 0.01, "continuous jungle seam")
	var level_twenty := game.progression.progress.capture()
	level_twenty.experience = CharacterProgress.threshold(20, true)
	game.progression.progress.restore(level_twenty)
	game.health.restore()
	game.health.invulnerability = 0
	var unarmored := game.health.current
	game.encounters._bee_stung(game.player, 88, game.player.position - Vector3.BACK, archer)
	var naked_damage := unarmored - game.health.current
	for slot in ["helmet", "armor", "legs", "boots"]:
		game.character_equipment.equip(slot, ItemStack.new(InventoryItem.apparel("celestial_" + slot), 1))
	game.health.restore()
	game.health.invulnerability = 0
	var armored := game.health.current
	game.encounters._bee_stung(game.player, 88, game.player.position - Vector3.BACK, archer)
	var celestial_damage := armored - game.health.current
	check(game.progression.progress.level() == 20 and game.character_equipment.complete_set() == "celestial", "recommended level and set compose correctly")
	check(naked_damage > 0 and is_equal_approx(celestial_damage * 2, naked_damage), "celestial set halves real groat damage")
	check(celestial_damage < armored * 0.25 and celestial_damage > armored * 0.1, "one groat remains threatening at the recommended build")
	game.queue_free()
	await process_frame
	print("Groatfields: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
