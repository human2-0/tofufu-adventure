extends SceneTree
## Actual swept staff hits around the actor, with one hit per target.

var failures: int = 0
var stage: Node3D
var actor: Node3D
var combat: PlayerCombat

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	actor = Node3D.new()
	stage.add_child(actor)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.equipment.knife_selected = false
	combat.equipment.staff_owned = true
	combat.equipment.staff_selected = true
	combat.staff.visible = true
	var knife := InventoryItem.weapon("knife")
	var staff := InventoryItem.weapon("sproutwood_staff")
	check(knife.weapon_level == 2 and knife.weapon_power == 10, "knife displays level two and power ten")
	check(staff.weapon_level == 1 and staff.weapon_power == 5, "staff displays level one and power five")
	check(is_equal_approx(combat.tuning.staff_length, 1.2), "staff has the shorter authored reach")
	combat.strike(Vector2.UP, 0.0)
	check(is_equal_approx(combat._melee_damage(), 5.0), "staff light hit applies power five")
	combat.reset()
	combat.combo.begin_attack()
	combat.combo.confirm_hit()
	combat.strike(Vector2.UP, 0.0)
	check(combat.attack_style == KnifeAttack.Style.STAB and is_equal_approx(combat._melee_damage(), 7.5), "staff earns the same quick combo stab at half knife damage")
	combat.reset()
	combat.strike(Vector2.UP, 1.0)
	check(combat.attack_style == KnifeAttack.Style.HEAVY and is_equal_approx(combat._melee_damage(), combat.tuning.heavy_damage * 0.5), "loaded staff follows knife power attack at half damage")
	combat.reset()
	combat.equipment.staff_selected = false
	combat.equipment.knife_selected = true
	combat.strike(Vector2.UP, 0.0)
	check(is_equal_approx(combat._melee_damage(), 10.0), "knife light hit applies power ten")
	combat.reset()
	combat.equipment.knife_selected = false
	combat.equipment.staff_selected = true
	var targets: Array[Damageable] = []
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		targets.append(_target(Vector3(direction.x, 0.0, direction.y) * 1.1 + Vector3.UP * combat.tuning.hand_height))
	combat.targets = targets
	await physics_frame
	combat.step(Vector2.UP, false, 1.0 / 60.0, Vector2.ZERO, false, true)
	check(combat.active and combat.attack_style == StaffAttack.TORNADO, "right button starts a staff tornado")
	check(ExplorationProtocol.combat(CombatState.capture(combat)), "staff tornado state is valid for co-op snapshots")
	for tick in 55:
		await physics_frame
		combat.step(Vector2.UP, false, 1.0 / 60.0, Vector2.ZERO, false, true)
	for target in targets:
		check(is_equal_approx(target.current, 95.0), "360-degree sweep hits each direction exactly once for staff power five")
	check(not combat.active, "tornado completes its recovery")
	for tick in 65:
		await physics_frame
		combat.step(Vector2.UP, false, 1.0 / 60.0, Vector2.ZERO, false, true)
	check(not combat.active, "holding right button does not auto-repeat tornado")
	stage.queue_free()
	await process_frame
	print("Staff combat: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _target(at: Vector3) -> Damageable:
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.position = at
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	shape.shape = sphere
	body.add_child(shape)
	stage.add_child(body)
	var target := Damageable.new()
	target.maximum = 100.0
	target.body = body
	body.add_child(target)
	return target

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)
