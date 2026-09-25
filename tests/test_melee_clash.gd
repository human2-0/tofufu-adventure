extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var first_actor := CharacterBody3D.new()
	var second_actor := CharacterBody3D.new()
	stage.add_child(first_actor)
	stage.add_child(second_actor)
	var first := PlayerCombat.new()
	first.actor = first_actor
	stage.add_child(first)
	var second := PlayerCombat.new()
	second.actor = second_actor
	stage.add_child(second)
	await process_frame
	var first_health := Damageable.new()
	var second_health := Damageable.new()
	stage.add_child(first_health)
	stage.add_child(second_health)
	first.owner_health = first_health
	second.owner_health = second_health
	first.active = true
	second.active = true
	first.clash.opponents = [second]
	var pose := SwordGeometry.pose(Vector3.ZERO, Vector2.UP, 0.5, first.tuning)
	first.clash.record(pose, true)
	second.clash.record(pose, true)
	var target := Damageable.new()
	target.body = second_actor
	stage.add_child(target)
	var opponent := first.clash.opponent_for(first, target)
	check(opponent == second, "overlapping active knife blades are a clash before player damage")
	first.clash.resolve(first, opponent)
	check(not first.active and not second.active, "a clash cancels both committed attacks")
	check(first_health.invulnerability >= first.tuning.clash_dodge_seconds and second_health.invulnerability >= second.tuning.clash_dodge_seconds, "a clash grants both players a brief dodge window")
	check(first.clash.sequence == 1 and second.clash.sequence == 1, "both fighters publish the same clash outcome")
	check(ExplorationProtocol.combat(CombatState.capture(first)), "clash state remains valid for a co-op snapshot")
	first.active = true
	second.active = true
	first.clash.record(pose, true)
	second.clash.record(SwordGeometry.pose(Vector3(5, 0, 0), Vector2.UP, 0.5, second.tuning), true)
	check(first.clash.opponent_for(first, target) == null, "separated blades do not create a false dodge")
	stage.queue_free()
	await process_frame
	print("Knife clash and dodge rules: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	printerr("FAIL: ", message)
