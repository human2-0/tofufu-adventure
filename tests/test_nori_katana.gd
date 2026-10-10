extends SceneTree
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var item := InventoryItem.weapon("nori_katana")
	var gear := CharacterEquipment.new()
	var stack := ItemStack.new(item, 1)
	gear.wearer_level = 4
	check(not gear.can_equip("combat_1", stack), "level four denied")
	gear.wearer_level = 5
	check(gear.can_equip("combat_1", stack), "level five admitted")
	check(ItemStack.restore(stack.capture()).item.id == item.id, "save round trip")
	var bag := PlayerInventory.new()
	WeaponTrade.purchase(bag, item.id)
	check(bag.count_item(item.id) == 1, "katana is obtainable at Kaji")
	var stage := Node3D.new()
	root.add_child(stage)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	floor_body.position.y = -0.5
	stage.add_child(floor_body)
	var actor: Player = load("res://game/player/player.tscn").instantiate()
	stage.add_child(actor)
	actor.set_physics_process(false)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.staff.visible = false
	gear.set_slot("combat_1", stack)
	var loadout := ActorLoadout.new()
	loadout.combat = combat
	loadout.equipment = gear
	loadout.inventory = bag
	stage.add_child(loadout)
	check(combat.equipment.nori_selected and combat.sword.nori, "loadout equips Nori art and combat")
	loadout.select(2)
	check(not combat.equipment.nori_selected and is_equal_approx(combat.melee_speed(), 1.0), "empty slot removes katana speed")
	loadout.select(1)
	check(combat._melee_length() > combat.tuning.blade_length, "longer physical reach")
	check(combat._melee_damage() < InventoryItem.weapon("edamame_sword").weapon_power, "lower normal damage than pod")
	check(is_equal_approx(combat.melee_speed(), 1.1), "ten percent speed")
	combat.combo.begin_attack()
	combat.combo.confirm_hit()
	combat.strike(Vector2.DOWN, 0.0)
	check(combat.attack_style == KnifeAttack.Style.REVERSE_SLASH, "confirmed hit chains a reverse slash")
	combat.reset()
	combat.sword_damage_multiplier = 1.5
	for at in [Vector3(0, 0.6, -2), Vector3(0, 0.6, 4), Vector3(2, 0.6, 0)]:
		var body := StaticBody3D.new()
		stage.add_child(body)
		body.position = at
		var target := Damageable.new()
		target.body = body
		body.add_child(target)
		combat.targets.append(target)
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(0.2, 3, 1)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	stage.add_child(wall)
	wall.position = Vector3(1, 1.5, 0)
	await physics_frame
	await physics_frame
	actor.velocity = Vector3.DOWN
	actor.move_and_slide()
	var far_body := StaticBody3D.new()
	far_body.collision_layer = 2
	far_body.position = Vector3(0, 0.55, -1.05)
	var far_shape := CollisionShape3D.new()
	var far_box := BoxShape3D.new()
	far_box.size = Vector3(0.1, 0.2, 0.1)
	far_shape.shape = far_box
	far_body.add_child(far_shape)
	stage.add_child(far_body)
	var far_target := Damageable.new()
	far_target.body = far_body
	far_body.add_child(far_target)
	combat.targets.append(far_target)
	await physics_frame
	await physics_frame
	var blade_pose := Transform3D(Basis.IDENTITY, Vector3(0, 0.55, 0))
	combat._set_melee_shape()
	combat._resolve_blade(Vector3.ZERO, blade_pose)
	check(far_target.current == 45.0, "katana collider hits beyond knife reach")
	combat._hit_targets.clear()
	far_target.current = 60.0
	combat.equipment.nori_selected = false
	combat._set_melee_shape()
	combat._resolve_blade(Vector3.ZERO, blade_pose)
	check(far_target.current == 60.0, "knife collider cannot hit that distance")
	combat.equipment.nori_selected = true
	combat.targets.erase(far_target)
	far_body.queue_free()
	combat.reset()
	combat.vitals.current = 74.0
	combat.plunge.start(combat, Vector2.UP)
	check(not combat.plunge.active and combat.vitals.current == 74, "insufficient SP refuses safely")
	combat.vitals.current = 100.0
	combat.step(Vector2.UP, false, 1.0 / 60, Vector2.ZERO, false, true)
	check(combat.plunge.active and combat.vitals.current == 25.0, "RMB spends exactly 75 SP")
	check(combat.targets[0].current == 60, "no damage before contact")
	check(ExplorationProtocol.combat(CombatState.capture(combat)), "airborne snapshot validates")
	var peak := 0.0
	for tick in 100:
		await physics_frame
		actor.velocity = combat.plunge.velocity(actor.velocity, actor.is_on_floor(), 1.0 / 60)
		actor.move_and_slide()
		peak = maxf(peak, actor.position.y)
		combat.step(Vector2.UP, false, 1.0 / 60, Vector2.ZERO, not actor.is_on_floor(), true)
		if combat.plunge.sequence > 0: break
	check(peak > 4.5 and actor.is_on_floor(), "actual aerial rise, vertical dive and floor collision")
	check(Vector2(actor.position.x, actor.position.z).length() < 0.01, "no horizontal drift")
	check(combat.plunge.sequence == 1, "one landing impact")
	check(combat.targets[0].current == 15.0, "exactly three normal scaled hits, no extra blade hit")
	check(combat.targets[1].current == 60 and combat.targets[2].current == 60, "radius and wall protection")
	check(combat.vitals.current == 25.0, "special does not refund normal hit SP")
	var snapshot := CombatState.capture(combat)
	check(ExplorationProtocol.combat(snapshot), "snapshot validates")
	var replica := PlayerCombat.new()
	replica.actor = actor
	stage.add_child(replica)
	CombatState.present(replica, snapshot, Vector2.UP)
	check(replica.sword.nori and combat.targets[0].current == 15.0, "replica cosmetic only")
	combat.reset()
	combat.vitals.current = 100
	combat.plunge.start(combat, Vector2.UP)
	check(not combat.plunge.active, "swap/reset cannot bypass plunge cooldown")
	combat.plunge.cooldown = 0.0
	actor.position.y = 3.0
	actor.velocity = Vector3.UP
	actor.move_and_slide()
	combat.plunge.start(combat, Vector2.UP)
	check(not combat.plunge.diving and actor.velocity.y > 0, "airborne activation allows aiming setup")
	var steering := combat.plunge.velocity(Vector3(3, 0, -2), false, 0.1)
	check(steering.x > 0 and steering.z < 0, "movement corrects target before dive")
	combat.plunge.released = true
	var committed := combat.plunge.velocity(Vector3(3, 0, -2), false, 0.5)
	check(committed == Vector3.DOWN * 24, "release commits a vertical thrust")
	combat.reset()
	check(not combat.plunge.active, "reset cancels flight")
	combat.equipment.nori_selected = false
	check(is_equal_approx(combat.melee_speed(), 1.0), "speed removed on unequip")
	check(combat.sword._model_id == "nori_katana" and combat.sword._model_instance != null, "supplied katana GLB is loaded for combat presentation")
	var model_pose := SwordGeometry.pose(Vector3.ZERO, Vector2.UP, -1, combat.tuning)
	combat.sword.present(model_pose, Vector2.UP, 0)
	var model_tip := model_pose * Vector3(0, 0, -combat.tuning.nori_length)
	check(combat.sword.model_tip_position().distance_to(model_tip) < 0.001, "katana model tip matches physical reach")
	stage.queue_free()
	await process_frame
	print("Nori Katana: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
