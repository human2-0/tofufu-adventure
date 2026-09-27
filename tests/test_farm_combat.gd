extends SceneTree
## Real scene coverage of practice targets, repeatable EXP and village protection.

class QuietInput extends PlayerCommandSource:
	func sample(_at: Vector3) -> PlayerCommand:
		return PlayerCommand.new()

var failures: int = 0
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	scene = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var source := QuietInput.new()
	scene.get_node("Player").add_child(source)
	scene.get_node("Player").command_source = source
	root.add_child(scene)
	var mobs: Array[TrainingMob] = []
	var dummies: Array[PracticeDummy] = []
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			mobs.append(child)
			child.set_physics_process(false)
			check(not child._protected(child.global_position), "mobs spawn outside the village")
		elif child is PracticeDummy:
			dummies.append(child)
	var forest_count := FarmCombatGrounds.FOREST_ARMORED_SPAWNS.size()
	check(mobs.size() == 15 + forest_count and dummies.size() == 3, "three outdoor packs, six rain reserves, forest snails and village dummies")
	check(mobs.filter(func(mob: TrainingMob) -> bool: return mob.visible).size() == 9 + forest_count, "camp and forest snails are active in dry weather")
	await _practice(dummies[0])
	await _rewards(mobs[0])
	await _safe_village(mobs[3])
	_armored_snail(mobs)
	_armored_quest()
	_stat_effects(dummies[0])
	scene.queue_free()
	await process_frame
	print("Farm combat: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _practice(dummy: PracticeDummy) -> void:
	scene.player.position = dummy.position + Vector3(0, 0.05, 1.4)
	scene.player.velocity = Vector3.ZERO
	await ticks(15)
	scene.combat.strike(Vector2.UP, 0.0)
	await ticks(35)
	check(dummy.hit_count == 1 and dummy.target.current < 200, "real knife sweep hits dummy once")
	check(scene.progression.progress.practice.sword == 1, "dummy trains sword once per actual swing")
	var before := dummy.target.current
	# The knife reaches farther than the 1.35-unit punch. Step into fist range.
	scene.player.position = dummy.position + Vector3(0, 0.05, 1.1)
	scene.combat.equipment.step(Vector2.UP, false, true, false, false, 0, 0.1)
	check(dummy.target.current < before, "fists hit the same practice target")
	check(scene.progression.progress.practice.fist == 1, "dummy trains fists separately")
	dummy.target.damage(999)
	await ticks(100)
	check(dummy.target.current == 200 and dummy.target.invulnerability == 0, "depleted dummy resets ready to hit again")
	dummy.target.damage(10)
	await ticks(245)
	check(dummy.target.current == 200, "idle practice target recovers between sessions")
	check(scene.encounters.experience == 0 and scene.encounters.mobs == 0 and scene.encounters.beans == 0, "dummies never award EXP, kills or loot")

func _rewards(mob: TrainingMob) -> void:
	scene.player.position = scene.world.ground_point(19, 8)
	mob.target.damage(999)
	mob.target.damage(999)
	check(scene.encounters.experience == 25 and scene.encounters.mobs == 1, "defeat awards EXP exactly once")
	check(scene.progression.progress.experience == 25, "enemy EXP reaches character progression")
	check(scene.hud._stats.text.contains("25 EXP"), "HUD receives earned EXP")
	mob._physics_process(23)
	check(mob.visible and mob.target.current == 60, "outdoor enemies respawn")
	mob.target.invulnerability = 0
	mob.target.damage(999)
	check(scene.encounters.experience == 50, "respawned enemies award EXP again")
	mob.velocity = Vector3.ZERO
	mob._hit(0, Vector3.UP * scene.combat.tuning.launcher_lift)
	check(is_equal_approx(mob.velocity.y, scene.combat.tuning.launcher_lift), "launcher impulse sends a live enemy upward")
	scene._respawn()
	check(scene.encounters.experience == 50, "earned EXP survives player defeat within session")

func _safe_village(mob: TrainingMob) -> void:
	mob.position = scene.world.ground_point(25, -21.6, 0.1)
	mob._home = scene.world.ground_point(25, -27, 0.1)
	scene.player.position = scene.world.ground_point(25, -20.5, 0.1)
	scene.player.velocity = Vector3.ZERO
	var hp: float = scene.health.current
	mob._windup = 0.01
	mob._knockback = Vector3(0, 0, 100)
	mob.set_physics_process(true)
	await ticks(80)
	check(not mob._protected(mob.global_position), "chase and knockback cannot enter village")
	check(scene.health.current == hp and not mob._warning.visible, "village entry cancels even a pending attack")
	mob.position = mob._home + Vector3(-10, 0, 0)
	scene.player.position = mob.position + Vector3(0, 0, 3)
	await ticks(130)
	check(Vector2(mob.position.x - mob._home.x, mob.position.z - mob._home.z).length() < 4, "distant enemies return toward their spawn")
	mob.set_physics_process(false)

func _armored_snail(mobs: Array[TrainingMob]) -> void:
	var armored: ArmoredSnail
	var armored_count := 0
	var level_one_names := 0
	for mob in mobs:
		if mob is ArmoredSnail:
			armored_count += 1
			if armored == null and mob.visible: armored = mob
			check(not FarmCombatGrounds.VILLAGE.has_point(Vector2(mob.position.x, mob.position.z)), "armored snails spawn outside the village")
		elif mob._nameplate.text == "SNAIL · LV 1":
			level_one_names += 1
	check(armored_count == 3 + FarmCombatGrounds.FOREST_ARMORED_SPAWNS.size() and armored != null and armored.LEVEL == 2, "level-two armored snails occupy rain reserves and forest clearings")
	check(level_one_names == 12, "normal snails display their level-one nameplate")
	if armored == null: return
	check(armored.protected_area == FarmCombatGrounds.VILLAGE.grow(FarmCombatGrounds.VILLAGE_SNAIL_MARGIN), "armored snails use a margin outside the village boundary")
	check(armored._armored_visual is ArmoredSnailVisuals, "armored snail uses its full 3D model")
	check(armored.target.maximum > 60 and armored.tuning.dry_damage > 12, "armored snail exceeds normal snail health and damage")
	var before := armored.target.current
	armored.facing = Vector3.BACK
	for kind in [Damageable.HitKind.KNIFE, Damageable.HitKind.MELEE, Damageable.HitKind.SOY, Damageable.HitKind.SLIME]:
		check(not armored.target.damage(2, Vector3.BACK, kind), "shell blocks every rear attack")
		check(not armored.target.damage(2, Vector3.RIGHT, kind), "shell blocks side attacks")
	check(is_equal_approx(armored.target.current, before), "shell hits never reduce health")
	check(armored.target.damage(20, Vector3.FORWARD, Damageable.HitKind.MELEE), "exposed front takes damage")
	check(armored.facing == Vector3.FORWARD and armored._defend > 0, "ambushed snail turns its shell toward attacker")
	check(not armored.target.damage(20, Vector3.FORWARD, Damageable.HitKind.KNIFE), "defensive turn blocks follow-up")
	armored._defend = 0.0
	armored._rest = 0.0
	armored._returning = false
	armored.free_roaming = true
	var player_position: Vector3 = scene.player.position
	scene.player.global_position = armored.global_position + Vector3.BACK * 4.0
	armored._choose_direction(0.01)
	check(armored._charging and armored._windup > 0.0, "rush telegraphs before moving")
	armored._choose_direction(0.8)
	var rush_motion := armored._choose_direction(0.01)
	check(rush_motion.length() > 7.0, "headbutt rush accelerates toward locked target")
	scene.player.global_position += Vector3.RIGHT * 3.0
	check(armored._choose_direction(0.01).is_equal_approx(rush_motion), "rush remains dodgeable without homing")
	scene.player.position = player_position
	var edamame_before: int = scene.encounters.pickups.size()
	scene.encounters.shell_drop_roll = func() -> float: return 0.05
	armored.target.invulnerability = 0.0
	armored.target.damage(999, -armored.facing, Damageable.HitKind.MELEE)
	check(scene.encounters.pickups.size() == edamame_before + 1, "armored snail drops one stacked Edamame pickup")
	check(scene.encounters.pickups.values().any(func(drop: SoybeanPickup) -> bool: return drop.count == 4), "armored snail stack contains four Edamame")
	var has_shell_piece := false
	for drop: WorldItemDrop in scene.world_items.pool.drops.values():
		if drop.item_id == "piece_of_shell": has_shell_piece = true
	check(has_shell_piece, "armored snail drops a Piece of Shell")
	check(SaveStore._world_items(scene.world_items.pool.capture()), "shell drops remain valid in saved adventures")

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _stat_effects(dummy: PracticeDummy) -> void:
	var progress: CharacterProgress = scene.progression.progress
	var data := progress.capture()
	data.experience = CharacterProgress.threshold(99, true)
	data.practice.sword = CharacterProgress.threshold(99)
	data.practice.defence = CharacterProgress.threshold(99)
	progress.restore(data)
	dummy.target.restore()
	dummy.target.invulnerability = 0
	scene.combat.reset()
	scene.combat._strength = 0
	scene.combat._damage(dummy.target)
	check(is_equal_approx(dummy.last_damage, scene.combat.tuning.light_damage * 3.45), "real damage combines capped weapon skill and character strength")
	scene.health.current = 100
	scene.health.invulnerability = 0
	scene.encounters._hurt_player(10, scene.player.position + Vector3.BACK)
	check(is_equal_approx(scene.health.current, 93.43), "defence skill mitigates actual unguarded enemy damage")
	scene._respawn()
	check(progress.level() == 99 and progress.skill("sword") == 99, "respawn retains trained levels and modifiers")

func _armored_quest() -> void:
	var giver: QuestGiver = scene.quest_giver
	giver._select_quest(1)
	giver._on_quest_accepted()
	scene.encounters.mob_defeated.emit(Vector3.ZERO)
	check(giver.quest.armored_count == 0, "ordinary kills do not count for armored hunt")
	for index in 50: scene.encounters.armored_snail_defeated.emit()
	check(giver.quest.armored_status == QuestState.Status.COMPLETED, "50 armored kills complete hunt objective")
	var restored := QuestState.new()
	restored.restore(giver.quest.capture())
	check(restored.armored_count == 50 and restored.armored_status == QuestState.Status.COMPLETED, "hunt survives save roundtrip")
	scene.inventory.remove_item("piece_of_shell", 1000)
	giver._on_reward_claimed()
	check(giver.quest.armored_status == QuestState.Status.COMPLETED, "delivery requires shell pieces")
	scene.inventory.add_item(InventoryItem.shell_piece(), 12)
	var beans: int = scene.inventory.count_item("mature_bean")
	var experience: int = scene.encounters.experience
	giver._on_reward_claimed()
	check(scene.inventory.count_item("piece_of_shell") == 2, "delivery consumes exactly ten shell pieces")
	check(scene.inventory.count_item("mature_bean") == beans + 20, "delivery awards twenty mature beans")
	check(scene.encounters.experience == experience + 1000, "delivery awards 1000 EXP")
	check(scene.progression.progress.experience == scene.encounters.experience, "quest EXP reaches character progression")
	giver._on_reward_claimed()
	check(scene.encounters.experience == experience + 1000, "reward cannot be claimed twice")
