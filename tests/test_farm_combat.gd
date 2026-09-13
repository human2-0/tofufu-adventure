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
	check(mobs.size() == 15 and dummies.size() == 3, "three outdoor packs with six rain reserves and three village dummies")
	check(mobs.filter(func(mob: TrainingMob) -> bool: return mob.visible).size() == 9, "nine snails active in dry weather")
	await _practice(dummies[0])
	await _rewards(mobs[0])
	await _safe_village(mobs[3])
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
