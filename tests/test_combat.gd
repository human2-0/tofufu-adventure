extends SceneTree

const FART_CLOUD := preload("res://game/combat/fart_cloud.gd")
var failures: int = 0
const DT: float = 1.0 / 60.0

func _initialize() -> void:
	_rules()
	_jump_height()
	call_deferred("_health")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _rules() -> void:
	var tuning := CombatTuning.new()
	var rules := MeleeRules.new(tuning)
	var other := MeleeRules.new(tuning)
	check(rules.step(true, DT) < 0.0, "holding never strikes before release")
	var light := rules.step(false, DT)
	check(light >= 0.0 and light < 1.0, "tap releases a light strike")
	check(rules.step(false, DT) < 0.0, "release strikes exactly once")
	rules.step(true, DT)
	check(rules.step(false, DT) < 0.0, "cooldown rejects another strike")
	for tick in 100:
		rules.step(true, DT)
	check(is_equal_approx(rules.charge, 1.0), "held charge is bounded")
	check(rules.step(false, DT) == 1.0, "full hold releases power slash")
	check(other.charge == 0.0 and other.cooldown == 0.0, "combat instances are isolated")

func _jump_height() -> void:
	var tap := _apex(false)
	var charged := _apex(true)
	check(tap > 1.5 and tap < 2.1, "heavier tap still clears ordinary obstacles")
	check(charged > 3.4 and charged < 4.0, "charged height is bounded")
	check(charged / tap > 1.9 and charged / tap < 2.1, "full charge doubles height, not launch velocity")
	print("Measured jump heights: tap %.2f, charged %.2f" % [tap, charged])

func _apex(held: bool) -> float:
	var motor := PlayerMotor.new(PlayerTuning.new())
	var command := PlayerCommand.new()
	command.jump_pressed = true
	command.jump_held = held
	var velocity := motor.step(command, Vector3.ZERO, true, DT)
	command.jump_pressed = false
	if held:
		for tick in 60:
			velocity = motor.step(command, velocity, true, DT)
			check(velocity.y == 0.0, "holding loads on the floor without launching")
		command.jump_held = false
		velocity = motor.step(command, velocity, true, DT)
	var height := velocity.y * DT
	var peak := height
	for tick in 150:
		velocity = motor.step(command, velocity, false, DT)
		height += velocity.y * DT
		peak = maxf(peak, height)
	return peak

func _health() -> void:
	var health := Damageable.new()
	health.maximum = 100.0
	root.add_child(health)
	check(health.damage(30), "damage is accepted when vulnerable")
	health.heal(20)
	check(health.current == 90, "soy-sized healing restores health")
	health.heal(999)
	check(health.current == 100, "healing clamps at maximum")
	health.invulnerability = 0.5
	check(not health.damage(30), "hurt immunity prevents repeated damage")
	health.invulnerability = 0.0
	health.damage(999)
	check(health.current == 0 and not health.damage(10), "depleted receiver cannot be hit twice")
	health.heal(20)
	check(health.current == 0, "healing does not resurrect depleted receivers")
	health.restore()
	check(health.current == 100, "explicit respawn restores health")
	health.queue_free()
	var cloud_target := Damageable.new()
	cloud_target.maximum = 30.0
	root.add_child(cloud_target)
	FART_CLOUD.spawn(root, Vector3.ZERO, [cloud_target])
	await physics_frame
	check(cloud_target.current == 22.0, "super dash fart cloud applies one light damage hit")
	await physics_frame
	check(cloud_target.current == 22.0, "fart cloud does not repeatedly damage the same target")
	cloud_target.queue_free()
	await process_frame
	print("Combat and super-jump rules: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
