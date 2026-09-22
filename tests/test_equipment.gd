extends SceneTree
## Exercise equipment through the real scene and incoming enemy damage path.
var failures: int = 0
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	scene = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.player.set_physics_process(false)
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
	scene.player.position = Vector3.ZERO
	await physics_frame
	var combat: PlayerCombat = scene.combat
	var equipment: PlayerEquipment = combat.equipment
	equipment.step(Vector2.UP, true, false, false, false, 0, 0.016)
	scene.encounters._hurt_player(12.0, Vector3(0, 0, -1))
	check(scene.health.current == 100.0, "front knife guard prevents real incoming damage")
	check(equipment.blocks(Vector3(0.7, 0, -0.7)), "45 degree attack is inside guard")
	check(not equipment.blocks(Vector3(1, 0, 0)), "side attack bypasses guard")
	scene.encounters._hurt_player(12.0, Vector3(0, 0, 1))
	check(scene.health.current == 88.0, "rear attack damages guarding player")
	combat.rules.step(true, 0.5)
	equipment.step(Vector2.UP, true, false, false, false, 0, 0.016)
	combat.step(Vector2.UP, false, 0.016)
	check(not combat.active and combat.rules.charge == 0.0, "guard cancels charge without releasing a slash")
	equipment.step(Vector2.UP, false, false, false, false, 0, 0.016)
	combat.strike(Vector2.UP, 0.0)
	equipment.step(Vector2.UP, true, false, true, false, 0, 0.016)
	check(not equipment.guarding and equipment.knife_owned, "committed slash cannot guard or drop mid-cut")
	combat.reset()
	equipment.step(Vector2.UP, true, false, true, false, 0, 0.016)
	check(not equipment.knife_owned and not equipment.guarding and not combat.sword.visible, "drop empties knife slot and disables defence")
	check(is_instance_valid(equipment.dropped), "drop creates a recoverable world knife")
	scene.player.position = Vector3(5, 0, 0)
	equipment.step(Vector2.UP, false, false, false, true, 0, 0.016)
	check(not equipment.knife_owned, "distant knife cannot be collected")
	scene.player.position = Vector3.ZERO
	equipment.step(Vector2.UP, false, false, false, true, 0, 0.016)
	check(equipment.knife_owned and equipment.knife_selected, "nearby knife can be recovered and equipped")
	var mob := TrainingMob.new()
	mob.position = Vector3(0, 0, -1)
	scene.add_child(mob)
	mob.set_physics_process(false)
	combat.targets = [mob.target]
	await physics_frame
	equipment.step(Vector2.UP, false, true, false, false, 1, 0.4)
	check(mob.target.current == 48.0, "F punches while knife remains equipped")
	equipment.step(Vector2.UP, false, true, false, false, 0, 0.016)
	check(mob.target.current == 48.0, "punch cooldown rejects repeat hit")
	var command := PlayerCommand.new()
	command.aim = Vector2.UP
	command.attack_held = true
	scene.character_equipment.set_slot("combat_2", null)
	command.weapon_slot = 2
	scene._on_command(command, 0.4)
	scene._on_command(command, 0.016)
	check(mob.target.current == 36.0 and not equipment.guarding, "fist slot attacks without knife defence")
	mob.position.y = 3.0
	equipment.step(Vector2.UP, false, true, false, false, 0, 0.4)
	check(mob.target.current == 36.0, "punch does not hit enemies above its reach")
	mob.position.y = 0.0
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.5, 0.1)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = Vector3(0, 0.6, -0.5)
	scene.add_child(wall)
	await physics_frame
	equipment.step(Vector2.UP, false, true, false, false, 0, 0.4)
	check(mob.target.current == 36.0, "solid wall occludes fist damage")
	scene.queue_free()
	await process_frame
	print("Equipment and guard: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
