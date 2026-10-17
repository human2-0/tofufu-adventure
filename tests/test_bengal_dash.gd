extends SceneTree
## Small real-physics fixture: charged route contacts, separate finisher and walls.

const DT := 1.0 / 60.0
var failures: int = 0
var actor: Player
var combat: PlayerCombat
var input: CoopTestInput
var stage: Node3D
var fist: int = 0
var speed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _run() -> void:
	Engine.max_physics_steps_per_frame = 1
	stage = Node3D.new()
	root.add_child(stage)
	_box(Vector3(0, -0.5, 5), Vector3(30, 1, 40), 1)
	actor = load("res://game/player/player.tscn").instantiate()
	input = CoopTestInput.new()
	stage.add_child(input)
	actor.command_source = input
	stage.add_child(actor)
	actor.set_physics_process(false)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.equipment.knife_selected = false
	combat.claws.selected = true
	ActorCombatMotion.configure(actor, combat)
	ActorCombatMotion.equipment(actor, true)
	actor.motor.spend_stamina = combat.vitals.spend
	actor.command_sampled.connect(_command)
	combat.weapon_trained.connect(func(_weapon: String) -> void: fist += 1)
	combat.speed_gear_trained.connect(func(units: int) -> void: speed += units)
	var middle := _target(Vector3(0.8, 0, 3))
	var final := _target(Vector3(0, 0.7, 6))
	combat.targets = [middle, final]
	input.aim = Vector2.DOWN
	input.aim_point = final.global_position
	await physics_frame
	await process_frame
	actor.set_physics_process(true)
	await ticks(3)
	SoloArenaFighter.stop_motion(actor)
	check(actor.ability_velocity.is_valid(), "arena motion reset must preserve the installed ability movement callback")
	combat.step(Vector2.DOWN, false, 1.99, Vector2.ZERO, false, true)
	combat.equipment.step(Vector2.DOWN, false, true, false, false, 0, DT)
	check(combat.claws.charging and not combat.claws.dashing and combat.vitals.current == 100, "1.99s cannot launch, spend SP or deal damage")
	combat.step(Vector2.DOWN, false, 0.01, Vector2.ZERO, false, false)
	check(not combat.claws.busy() and combat.claws.cooldown == 0 and final.current == 1000, "early release cancels for free")
	combat.step(Vector2.DOWN, false, 2.0, Vector2.ZERO, false, true)
	check(combat.claws.dashing and combat.claws.launch_sequence == 1 and combat.vitals.current == 80, "two-second charge launches once and pays 20 SP")
	check(fist == 0 and speed == 0, "charging and launching cannot grant practice")
	await ticks(24)
	check(is_equal_approx(1000 - middle.current, 16), "route contact damages an intermediate target only once")
	check(is_equal_approx(1000 - final.current, 64), "slightly elevated enemy receives one contact and a separate three-times cut")
	check(final.paralysis > 3.8 and final.paralysis <= 4, "only finishing cut applies four-second enemy paralysis")
	check(middle.paralysis == 0, "passing contact does not apply finishing paralysis")
	check(actor.position.z > 5 and actor.position.z < 5.6 and actor.collision_mask == 3, "dash approaches aimed enemy and restores actor collisions")
	check(fist == 1 and speed == 1, "whole multi-hit skill trains fists and attack speed once each")
	var saved := CombatState.capture(combat)
	check(ExplorationProtocol.combat(JSON.parse_string(JSON.stringify(saved))), "charged dash record survives wire format")
	for field in ["claw_charge", "claw_remaining"]:
		var invalid := saved.duplicate(true)
		invalid[field] = NAN
		check(not ExplorationProtocol.combat(invalid), "nonfinite charge and dash timers rejected")
	combat.claws.cooldown = 0
	combat.equipment._punch_time = 0
	combat.step(Vector2.DOWN, false, 0, Vector2.ZERO, false, false)
	combat.step(Vector2.DOWN, false, 1, Vector2.ZERO, false, true)
	var charging := CombatState.capture(combat)
	CombatState.restore(combat, charging)
	check(not combat.claws.busy(), "checkpoint restoration cannot resume a saved attack")
	combat.step(Vector2.DOWN, false, 0, Vector2.ZERO, false, false)
	combat.step(Vector2.DOWN, false, 1, Vector2.ZERO, false, true)
	combat.vitals.current = 0
	combat.step(Vector2.DOWN, false, 1, Vector2.ZERO, false, true)
	check(not combat.claws.busy() and combat.claws.cooldown == 0, "SP exhausted during charge safely rejects launch")
	await _interrupted(final, middle)
	await _wall(final, middle)
	stage.queue_free()
	await process_frame
	print("Bengal charged dash: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _interrupted(final: Damageable, middle: Damageable) -> void:
	actor.position = Vector3.ZERO
	actor.velocity = Vector3.ZERO
	combat.claws.cancel()
	combat.claws.cooldown = 0
	combat.equipment._punch_time = 0
	combat.vitals.current = 100
	final.current = 1000
	middle.current = 1
	middle.depleted.connect(combat.interrupt, CONNECT_ONE_SHOT)
	await ticks(3)
	combat.step(Vector2.DOWN, false, 0, Vector2.ZERO, false, false)
	combat.step(Vector2.DOWN, false, 2, Vector2.ZERO, false, true)
	var sequence := combat.claws.sequence
	await ticks(30)
	check(middle.current == 0 and final.current == 1000 and combat.claws.sequence == sequence, "interrupting a contact callback cannot leak a finishing attack")
	check(fist == 2 and speed == 2, "interrupted skill credits only its confirmed contact")

func _wall(final: Damageable, middle: Damageable) -> void:
	actor.position = Vector3.ZERO
	actor.velocity = Vector3.ZERO
	final.current = 1000
	middle.current = 1000
	combat.claws.cancel()
	combat.claws.cooldown = 0
	combat.equipment._punch_time = 0
	combat.vitals.current = 100
	_box(Vector3(0, 1.5, 3), Vector3(6, 3, 0.3), 1)
	await ticks(3)
	combat.step(Vector2.DOWN, false, 0, Vector2.ZERO, false, false)
	combat.step(Vector2.DOWN, false, 2, Vector2.ZERO, false, true)
	await ticks(30)
	check(actor.position.z < 2.6 and not combat.claws.dashing, "solid wall ends dash without tunneling")
	check(final.current == 1000 and middle.current == 1000, "neither route contacts nor finishing rift damage through terrain")
	check(fist == 2 and speed == 2, "blocked skill cannot grant practice")
	combat.replica_view = true
	combat.claws.cooldown = 0
	combat.equipment._punch_time = 0
	var sp := combat.vitals.current
	combat.claws.fire(combat, Vector2.DOWN)
	combat.claws.hits.sweep(combat, Vector3.ZERO, Vector3.BACK * 7)
	combat.claws.strike(combat, true)
	check(combat.vitals.current == sp and final.current == 1000 and fist == 2, "replicas cannot start, spend, hit or train")

func _command(command: PlayerCommand, delta: float) -> void:
	combat.equipment.step(command.aim, command.guard_held, command.attack_held, false, false, 0, delta)
	combat.step(command.aim, false, delta, Vector2.ZERO, false, command.guard_held)

func _target(at: Vector3) -> Damageable:
	var body := _box(at + Vector3.UP * 0.55, Vector3(0.5, 1.1, 0.5), 2)
	var target := Damageable.new()
	target.maximum = 1000
	target.trains_weapons = true
	target.paralysis_allowed = true
	target.body = body
	body.add_child(target)
	target.set_physics_process(false)
	return target

func _box(at: Vector3, size: Vector3, layer: int) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	stage.add_child(body)
	body.position = at
	return body
