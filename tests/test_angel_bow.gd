extends SceneTree
## Real sweeps, exact damage, reload/charge gates, occluded sphere and replicas.

var failures: int = 0
var stage: Node3D
var combat: PlayerCombat
var bow: AngelBow
var trained: int = 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func dummy(at: Vector3) -> PracticeDummy:
	var result := PracticeDummy.new()
	result.maximum_health = 2000
	stage.add_child(result)
	result.position = at
	result.target.trains_weapons = true
	return result

func wall(at: Vector3, size: Vector3) -> StaticBody3D:
	var result := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	result.add_child(shape)
	stage.add_child(result)
	result.position = at
	return result

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var actor := CharacterBody3D.new()
	stage.add_child(actor)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.equipment.knife_selected = false
	combat.gun.selected = false
	combat.sotjet.selected = false
	bow = combat.bow
	bow.selected = true
	combat.weapon_trained.connect(func(_weapon: String) -> void: trained += 1)
	var target := dummy(Vector3(0, 0, -5))
	combat.targets = [target.target]
	await ticks(3)
	var aim := Vector3(0, 0.65, -5)
	bow.step(true, false, Vector2.UP, aim, 0.016)
	bow.step(true, false, Vector2.UP, aim, 0.016)
	check(bow.sequence == 1 and bow.reload_remaining > 1.9, "one arrow immediately starts a two-second reload")
	await ticks(8)
	check(target.target.current == 1950, "body arrow deals 2.5 times the normal 20-damage soybean bullet")
	bow.step(true, true, Vector2.UP, aim, 1.0)
	check(bow.sequence == 1 and bow.charge == 0, "RMB cannot charge or shoot during reload")
	bow.step(false, false, Vector2.UP, aim, 1.0)
	bow.step(true, false, Vector2.UP, Vector3(0, 1.85, -5), 0.016)
	await ticks(8)
	check(target.target.current == 1850 and trained == 2, "headshot deals 100 and confirmed hits train shooting")
	var cover := wall(Vector3(0, 1, -2.5), Vector3(3, 3, 0.02))
	bow.step(false, false, Vector2.UP, aim, 2.0)
	await ticks(2)
	bow.step(true, false, Vector2.UP, aim, 0.016)
	await ticks(8)
	check(target.target.current == 1850, "thin world cover absorbs a 96m/s arrow")
	cover.position.z = -0.2
	bow.step(false, false, Vector2.UP, aim, 2.0)
	await ticks(2)
	bow.step(true, false, Vector2.UP, aim, 0.016)
	await ticks(8)
	check(target.target.current == 1850, "cover between actor and muzzle prevents firing through walls")
	cover.free()
	var near := dummy(Vector3(2, 0, -5))
	var far := dummy(Vector3(4.6, 0, -5))
	var above := dummy(Vector3(0, 4.0, -5))
	var blocked := dummy(Vector3(-2.5, 0, -5))
	var shield := wall(Vector3(-1.3, 1, -5), Vector3(0.05, 4, 3))
	combat.targets = [target.target, near.target, near.target, far.target, above.target, blocked.target]
	bow.step(false, false, Vector2.UP, aim, 2.0)
	var before_sp := combat.vitals.current
	bow.step(false, true, Vector2.UP, aim, 0.6)
	check(bow.charge == 0.6 and combat.vitals.current == before_sp, "partial charge spends no stamina")
	bow.step(false, false, Vector2.UP, aim, 0.016)
	check(bow.charge == 0.0, "releasing RMB cancels an incomplete charge")
	bow.step(true, true, Vector2.UP, aim, 1.25)
	check(combat.vitals.current == before_sp - 25 and bow.empowered and bow.cooldown == 6, "RMB takes priority over LMB and pays exactly 25 SP on a full charge")
	await ticks(8)
	check(target.target.current == 1750, "charged body arrow hits primary once for double damage")
	check(near.target.current == 1950 and far.target.current == 2000 and above.target.current == 2000, "flame sphere deals one pulse in a true 3.5m radius with no duplicate receiver hits")
	check(blocked.target.current == 2000 and bow.burst_sequence == 1, "cover blocks splash and one enemy contact produces one sphere")
	var shot := bow.sequence
	bow.step(true, true, Vector2.UP, aim, 6.0)
	check(bow.sequence == shot, "holding RMB cannot repeat a charged shot without releasing")
	bow.step(false, false, Vector2.UP, aim, 0.016)
	combat.vitals.current = 24
	bow.step(false, true, Vector2.UP, aim, 1.25)
	check(bow.sequence == shot and bow.charge == 0 and combat.vitals.current == 24, "insufficient stamina cannot launch or charge the skill")
	combat.vitals.current = 100
	bow.step(false, false, Vector2.UP, aim, 0.016)
	bow.step(false, true, Vector2.UP, aim, 0.8)
	combat.reset()
	check(bow.charge == 0, "menu/equipment cancellation clears the held charge")
	bow.reload_remaining = 1.2
	bow.cooldown = 3
	combat.reset()
	check(bow.reload_remaining == 1.2 and bow.cooldown == 3, "switching equipment cannot bypass reload or skill cooldown")
	shield.free()
	var mirror := AngelArrow.new()
	mirror.bow = bow
	mirror.empowered = true
	mirror.authoritative = false
	mirror.targets = [target.target, near.target]
	stage.add_child(mirror)
	var primary_hp := target.target.current
	mirror.resolve(target, target.target.global_position)
	AngelFlameSphere.pulse(mirror, target.target.global_position, target.target)
	check(target.target.current == primary_hp and near.target.current == 1950, "replica arrow and sphere cannot apply outcomes")
	mirror.free()
	var snapshot := CombatState.capture(combat)
	check(ExplorationProtocol.combat(JSON.parse_string(JSON.stringify(snapshot))), "new bow snapshot round-trips through bounded JSON")
	for edit in [{"bow_charge": 2.0}, {"bow_reload": -1}, {"bow_velocity": [96, 96, 0]}, {"bow_cooldown": NAN}, {"gun": true}]:
		var bad := snapshot.duplicate(true)
		bad.merge(edit, true)
		check(not ExplorationProtocol.combat(bad), "malformed or mutually exclusive bow state is rejected: " + str(edit))
	bow.clear_flights()
	bow.reload_remaining = 0
	combat.gun.enhancement_multiplier = 1.2
	bow.step(true, false, Vector2.UP, aim, 0.016)
	var enhanced: AngelArrow
	for child in bow.get_children():
		if child is AngelArrow and not child.is_queued_for_deletion(): enhanced = child
	check(enhanced != null and enhanced.body_damage == 60 and enhanced.head_damage == 120, "per-item enhancement raises arrow power by 20 percent")
	check(bow.reload_remaining == 2.0, "enhancement retains a single arrow and the full reload")
	bow.clear_flights()
	check(enhanced.is_queued_for_deletion() and not enhanced.is_physics_processing(), "arena cleanup immediately disarms in-flight arrows")
	await _world_flame()
	stage.free()
	print("Angel bow: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _world_flame() -> void:
	var front := dummy(Vector3(-7.5, 0, -9))
	var behind := dummy(Vector3(-10, 0, -11.5))
	var barrier := wall(Vector3(-10, 1, -10), Vector3(8, 4, 0.1))
	combat.targets = [front.target, behind.target]
	bow.reload_remaining = 0
	bow.cooldown = 0
	combat.vitals.current = 100
	bow.step(false, false, Vector2.UP, Vector3.ZERO, 0.016)
	await ticks(2)
	var before := bow.burst_sequence
	bow.step(false, true, Vector2(-1, -1).normalized(), Vector3(-10, 0.65, -10), 1.25)
	await ticks(12)
	check(bow.burst_sequence == before + 1, "a charged arrow hitting world cover still produces one visible flame burst")
	check(is_equal_approx(front.target.current, 1940), "surface flame impact can damage an exposed nearby enemy once: hp=%s at=%s" % [front.target.current, bow.burst_at])
	check(behind.target.current == 2000, "surface flame cannot damage an enemy behind the struck wall")
	barrier.free()
