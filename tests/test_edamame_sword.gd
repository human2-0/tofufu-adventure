extends SceneTree
var failures: int = 0
var pushed := Vector3.ZERO

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var item := InventoryItem.weapon("edamame_sword")
	var equipment := CharacterEquipment.new()
	var stack := ItemStack.new(item, 1)
	check(not equipment.can_equip("combat_1", stack), "low level cannot wear sword")
	equipment.wearer_level = 5
	check(equipment.can_equip("combat_1", stack), "level five can wear sword")
	check(ItemStack.restore(stack.capture()).item.id == item.id, "item survives save round trip")
	var bag := PlayerInventory.new()
	WeaponTrade.purchase(bag, item.id)
	check(bag.count_item(item.id) == 1, "free purchase without currency")
	var stage := Node3D.new()
	root.add_child(stage)
	var actor := Node3D.new()
	stage.add_child(actor)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.equipment.pod_selected = true
	combat.sword.set_pod(true)
	check(is_equal_approx(combat._melee_damage(), 12.0), "twenty percent stronger light strike")
	var targets: Array[Damageable] = []
	for at in [Vector3(0, 0.7, -3), Vector3(0, 0.7, 3), Vector3(0, 0.7, -5), Vector3(2, 0.7, -2)]:
		var body := StaticBody3D.new()
		stage.add_child(body)
		body.position = at
		var target := Damageable.new()
		target.body = body
		body.add_child(target)
		targets.append(target)
	combat.targets = targets
	var recipient: Player = load("res://game/player/player.tscn").instantiate()
	stage.add_child(recipient)
	recipient.set_physics_process(false)
	targets[0].pushed.connect(recipient.apply_push)
	targets[0].hit.connect(func(_amount: float, impulse: Vector3) -> void: pushed = impulse)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 3, 0.6)
	shape.shape = box
	wall.add_child(shape)
	stage.add_child(wall)
	wall.position = Vector3(1, 0.7, -1)
	await physics_frame
	await physics_frame
	combat.step(Vector2.UP, false, 0.016, Vector2.ZERO, false, true)
	check(targets[0].current == 52, "wind damages forward target")
	check(targets[1].current == 60 and targets[2].current == 60, "rear and distant targets safe")
	check(targets[3].current == 60, "wall blocks wind")
	check(combat.podburst.sequence == 1, "RMB fires once")
	check(pushed == Vector3(0, 0, -18), "wind supplies outward knockback")
	check(recipient.velocity == Vector3(0, 0, -18), "player push contract receives the stronger wind")
	check(combat._melee_length() == 0.95 and combat._melee_width() == 0.36, "rescaled pod art matches physical blade")
	check(ExplorationProtocol.combat(CombatState.capture(combat)), "snapshot validates")
	combat.reset()
	combat.step(Vector2.UP, false, 0.016, Vector2.ZERO, false, true)
	check(combat.podburst.sequence == 1, "reset or weapon swap cannot bypass cooldown")
	var replica := PlayerCombat.new()
	replica.actor = actor
	stage.add_child(replica)
	var snapshot := CombatState.capture(combat)
	CombatState.present(replica, snapshot, Vector2.UP)
	check(replica.sword.pod and replica.equipment.pod_selected, "replica presents supplied pod artwork")
	check(targets[0].current == 52, "replica presentation never damages")
	combat.step(Vector2.UP, false, 3.1)
	combat.step(Vector2.UP, false, 0.016, Vector2.ZERO, false, true)
	check(combat.podburst.sequence == 2, "new press works after cooldown")
	stage.queue_free()
	await process_frame
	print("Edamame sword: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
