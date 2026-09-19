extends SceneTree

class ScriptedInput extends PlayerCommandSource:
	var command := PlayerCommand.new()
	func sample(_position: Vector3) -> PlayerCommand:
		var result := PlayerCommand.new()
		result.move = command.move
		result.aim = command.aim
		result.attack_held = command.attack_held
		result.jump_pressed = command.jump_pressed
		result.jump_held = command.jump_held
		command.jump_pressed = false
		return result

var failures: int = 0
var scene: Node3D
var player: Player
var source: ScriptedInput

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	scene = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	player = scene.get_node("Player")
	source = ScriptedInput.new()
	player.add_child(source)
	player.command_source = source
	root.add_child(scene)
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
	await ticks(5)
	await _prop_boundaries()
	await _harvest_and_heal()
	await _magnetic_pickup()
	await _occlusion_and_sword()
	await _river_and_farm()
	await _mob_and_respawn()
	scene.queue_free()
	await process_frame
	print("Sandbox integration tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _harvest_and_heal() -> void:
	var plant: Damageable = scene.combat.targets[0]
	player.position = plant.global_position + Vector3(1.2, -0.6, 0)
	player.velocity = Vector3.ZERO
	source.command.aim = Vector2.LEFT
	scene.health.damage(40)
	await ticks(5)
	source.command.attack_held = true
	await ticks(2)
	source.command.attack_held = false
	await ticks(26)
	check(plant.current == 0, "real input command harvests soy with a tap")
	check(scene.encounters.props == 1, "harvest is counted once")
	await ticks(100)
	check(scene.encounters.beans == 2, "destroyed soy drops two collectible 2D beans")
	check(scene.inventory.count_item("soybean") == 2, "collected beans are stored in inventory")
	check(scene.health.current == 60, "collecting soy into bag does not immediately heal")
	var stack: ItemStack = scene.inventory.get_slot(0)
	scene.character_equipment.set_slot("healing_1", stack)
	scene.inventory.set_slot(0, null)
	check(scene.character_equipment.get_slot("healing_1").count == 2, "soybean stack equipped to healing slot")
	var used: bool = scene.healing.use_slot("healing_1")
	check(used, "eating equipped soybean succeeds")
	check(scene.character_equipment.get_slot("healing_1").count == 1, "eating consumes 1 soybean from stack")
	check(scene.healing.cooldown_remaining > 1.8, "eating soybean triggers 2s cooldown")
	check(not scene.healing.use_slot("healing_1"), "cannot eat another soybean during 2s cooldown")
	var hp_before: float = scene.health.current
	await ticks(30)
	check(scene.health.current > hp_before, "soybean gradually restores health over time")
	await ticks(130)
	check(absf(scene.health.current - 85.0) < 0.5, "soybean restores +25 HP total gradually")
	var prop := plant.get_parent() as HarvestProp
	prop._physics_process(30)
	check(prop.visible and plant.current == plant.maximum, "plants regrow for repeat testing")

func _occlusion_and_sword() -> void:
	source.command.aim = Vector2.UP
	var prop := HarvestProp.new()
	prop.kind = 1
	prop.position = scene.world.ground_point(-25, -7)
	scene.add_child(prop)
	scene.combat.targets.append(prop.target)
	player.position = scene.world.ground_point(-25, -5.6, 0.05)
	player.velocity = Vector3.ZERO
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2, 2, 0.15)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = scene.world.ground_point(-25, -6.3, 1)
	scene.add_child(wall)
	await ticks(5)
	scene.combat.strike(Vector2.UP, 1.0)
	await ticks(32)
	check(prop.target.current == 40, "solid wall blocks sword")
	wall.queue_free()
	await ticks(3)
	player.position = scene.world.ground_point(-25, -4.3, 0.05)
	scene.combat.strike(Vector2.UP, 0.0)
	await ticks(32)
	check(prop.target.current == 40, "crate beyond light reach survives a slash")
	player.position = scene.world.ground_point(-25, -5.6, 0.05)
	source.command.attack_held = true
	await ticks(55)
	source.command.attack_held = false
	await ticks(32)
	check(prop.target.current == 0, "charged slash breaks a nearby crate")

func _river_and_farm() -> void:
	player.position = Vector3(7, 0.1, 4)
	player.velocity = Vector3.ZERO
	await ticks(10)
	source.command.move = Vector2.RIGHT
	await ticks(95)
	source.command.move = Vector2.ZERO
	check(player.position.x > 15 and player.position.y > -0.1, "bridge supports an uninterrupted crossing")
	player.position = Vector3(11, 0, 10)
	player.velocity = Vector3.ZERO
	await ticks(40)
	check(player.is_on_floor() and player.position.y < -0.5, "river has a shallow solid bed")
	check(player.surface_speed < 1, "wading slows movement")
	# Approach beside the now-solid storage sign, along the open farm lane.
	player.position = scene.world.ground_point(-20.5, -10, 0.1)
	player.velocity = Vector3.ZERO
	await ticks(30)
	source.command.move = Vector2.UP
	await ticks(70)
	source.command.move = Vector2.ZERO
	await ticks(20)
	check(player.position.z < -16 and player.is_on_floor(), "farm lane climbs to seed bank on physical terrain")
	check(player.position.y > 1.0, "seed bank approach has real elevation")
	player.position = Vector3(20, 0.1, -3)
	player.velocity = Vector3.ZERO
	await ticks(10)
	source.command.move = Vector2.UP
	await ticks(50)
	source.command.move = Vector2.ZERO
	check(player.position.z > -6, "item shop walls block traversal")

func _mob_and_respawn() -> void:
	var mob: TrainingMob
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			mob = child
			break
	player.position = scene.world.ground_point(-26, 18, 0.05)
	player.velocity = Vector3.ZERO
	mob.position = scene.world.ground_point(-26, 19.2, 0.05)
	mob._home = mob.position
	scene.health.invulnerability = 0
	var before: float = scene.health.current
	mob.set_physics_process(true)
	await ticks(12)
	check(scene.health.current == before and mob._warning.visible, "slime telegraphs before dealing damage")
	await ticks(45)
	check(scene.health.current < before, "slime hit damages player after warning")
	var blocker := StaticBody3D.new()
	var blocker_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 0.15)
	blocker_shape.shape = box
	blocker.add_child(blocker_shape)
	scene.add_child(blocker)
	blocker.position = (mob.position + player.position) * 0.5 + Vector3.UP * 0.6
	await ticks(2)
	check(not mob._can_reach_quarry(), "slime attacks cannot pass through solid cover")
	blocker.queue_free()
	await ticks(2)
	mob.target.damage(100)
	check(not mob.visible and scene.encounters.mobs == 1, "defeated slime disappears and counts once")
	mob._physics_process(23)
	check(mob.visible and mob.target.current == 60, "slime respawns with fresh health")
	mob.set_physics_process(false)
	scene.health.invulnerability = 0
	scene.health.damage(999)
	check(player.position.distance_to(Vector3(0, 0.1, 0)) < 0.1, "defeat returns player to safe spawn")
	check(scene.health.current == 100, "defeat restores player health")

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func _magnetic_pickup() -> void:
	var collector := Node3D.new()
	# Keep the magnetic-follow fixture on the open nursery lane; hills have occlusion.
	collector.position = scene.world.ground_point(0, 4)
	scene.add_child(collector)
	var bean := SoybeanPickup.new()
	bean.collector = collector
	bean.position = collector.position + Vector3(5, 0, 0)
	scene.add_child(bean)
	var collections: Array[int] = [0]
	bean.collected.connect(func() -> void: collections[0] += 1)
	await ticks(80)
	check(is_instance_valid(bean) and not bean._attracted, "distant beans wait rather than healing remotely")
	check(absf(bean.global_position.y - scene.world.ground_point(bean.position.x, bean.position.z).y - 0.2) < 0.15, "drop gravity settles on the ground without drifting")
	collector.position = scene.world.ground_point(bean.position.x - 3.0, bean.position.z)
	await ticks(1)
	check(bean._attracted and collections[0] == 0, "proximity starts attraction before contact heals")
	collector.position.x -= 2.0
	collector.position.y = scene.world.ground_point(collector.position.x, collector.position.z).y
	for tick in 120:
		collector.position.x -= 6.5 / 60.0
		collector.position.y = scene.world.ground_point(collector.position.x, collector.position.z).y
		await ticks(1)
		if not is_instance_valid(bean):
			break
	check(collections[0] == 1, "latched bean follows outside trigger radius and catches a walking collector exactly once")
	if is_instance_valid(bean):
		bean.queue_free()
	collector.queue_free()

func _prop_boundaries() -> void:
	var fixture := Node3D.new()
	scene.add_child(fixture)
	fixture.position = Vector3(0, 30, 0)
	FarmBuildings.cottage(fixture, Vector3.ZERO, "", Color.WHITE, Vector3(6, 3, 4))
	var tree: Node3D = load("res://game/world/tree.tscn").instantiate()
	fixture.add_child(tree)
	tree.position.x = 10
	var rail := MeadowGeometry.box(fixture, Vector3(20, 1, 0), Vector3(0.1, 0.2, 4), Color.WHITE, true)
	rail.rotation.y = PI / 2
	await ticks(2)
	var space := scene.get_world_3d().direct_space_state
	for segment in [
		[Vector3(1.62, 34.9, -3), Vector3(1.62, 34.9, 1)],
		[Vector3(10, 32.1, -3), Vector3(10, 32.1, 3)],
		[Vector3(10, 32.9, -3), Vector3(10, 32.9, 3)],
		[Vector3(21.5, 31, -1), Vector3(21.5, 31, 1)]]:
		check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(segment[0], segment[1], 1)).is_empty(), "chimney, both canopies and rotated rail block world rays")
	var motion := PhysicsTestMotionParameters3D.new()
	motion.from = Transform3D(Basis.IDENTITY, Vector3(10, 31.9, -3))
	motion.motion = Vector3(0, 0, 6)
	check(PhysicsServer3D.body_test_motion(player.get_rid(), motion), "player capsule cannot traverse elevated tree canopy")
	fixture.queue_free()
	await ticks(2)
