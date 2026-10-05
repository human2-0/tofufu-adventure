extends SceneTree
## Real shell/foot contacts, independent armor HP, one swing, loot and replica state.
var failures: int = 0
var world: Node3D
var snail: ArmoredSnail

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	snail = ArmoredSnail.new()
	world.add_child(snail)
	snail.set_physics_process(false)
	snail._defend_cooldown = 999.0
	await physics_frame
	await physics_frame
	var body_health := snail.target.current
	for side in [Vector3.RIGHT, Vector3.BACK, Vector3.LEFT, Vector3.FORWARD]:
		var contact := _ray(side * 2.0 + Vector3.UP * 0.2, -side * 2.0 + Vector3.UP * 0.2)
		check(not contact.is_empty(), "low aim contacts broad foot")
		if contact.is_empty(): continue
		check(snail.target.damage(2, -side, Damageable.HitKind.SOY, contact.position), "foot is vulnerable from every direction")
	check(snail.shell_health == 65 and snail.target.current == body_health - 8, "foot damage bypasses shell HP")
	var contact := _ray(Vector3(-2, 0.8, 0), Vector3(2, 0.8, 0))
	check(not contact.is_empty(), "shell collider matches visible dome")
	body_health = snail.target.current
	if not contact.is_empty():
		check(not snail.target.damage(10, Vector3.RIGHT, Damageable.HitKind.SOY, contact.position), "shell blocks body damage")
	check(snail.shell_health == 55 and snail.target.current == body_health, "shell has separate 65 HP")
	var snapshot := EncounterState.mob(snail)
	snail.set_shell_health(0)
	EncounterState.apply_mob(snail, snapshot)
	check(snail.shell_health == 55 and snail._armored_visual._shell.visible, "partial shell HP survives snapshot restore")
	snail.target.damage(100, Vector3.RIGHT, Damageable.HitKind.KNIFE, Vector3(0.5, 0.8, 0))
	check(snail.shell_health == 0 and snail.target.current == body_health, "breaking hit never spills into body HP")
	check(not snail._armored_visual._shell.visible, "broken shell disappears")
	check(snail.target.damage(10, Vector3.RIGHT, Damageable.HitKind.MELEE, Vector3(0.4, 0.6, 0)), "body is vulnerable after shell breaks")
	await physics_frame
	await physics_frame
	check(_ray(Vector3(-2, 1.1, -0.1), Vector3(2, 1.1, -0.1)).is_empty(), "broken dome no longer intercepts shots")
	_check_loot()
	snail.target.restore()
	check(snail.shell_health == 65 and snail._armored_visual._shell.visible, "respawn restores intact shell")
	snail.target.invulnerability = 0
	await _check_swing()
	world.queue_free()
	await process_frame
	print("Armored shell: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _ray(start: Vector3, finish: Vector3) -> Dictionary:
	return world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, finish, 2))

func _check_loot() -> void:
	var encounters := SandboxEncounters.new()
	world.add_child(encounters)
	encounters.set_physics_process(false)
	var drops: Array[String] = []
	encounters.shell_drop = func(id: String, _at: Vector3) -> void: drops.append(id)
	encounters.shell_drop_roll = func() -> float: return 0.0
	encounters._mob_defeated(Vector3.ZERO, snail)
	check(drops.size() == 2, "broken shell doubles successful drop to two pieces")
	drops.clear()
	snail.set_shell_health(65)
	encounters._mob_defeated(Vector3.ZERO, snail)
	check(drops.size() == 1, "intact shell retains one-piece drop")
	drops.clear()
	snail.set_shell_health(0)
	encounters.shell_drop_roll = func() -> float: return 1.0
	encounters._mob_defeated(Vector3.ZERO, snail)
	check(drops.is_empty(), "doubling quantity preserves existing drop chance")

func _check_swing() -> void:
	var game: Node3D = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	_check_protocol(game)
	game.combat.targets.clear()
	game.combat.targets.append(snail.target)
	snail.position.y = 20.0
	await physics_frame
	await physics_frame
	var pose := Transform3D(Basis.IDENTITY, Vector3(0, 20.7, 0.7))
	for index in 10: game.combat._resolve_blade(Vector3(0, 20, 1), pose)
	check(snail.shell_health < 65 and snail.shell_health > 0, "repeated blade samples consume shell HP only once per swing")
	check(game.combat._hit_targets.has(snail.target), "absorbed melee hit is remembered for the swing")
	game.queue_free()
	await process_frame

func _check_protocol(game: Node3D) -> void:
	var data := CoopWorld.capture(game)
	data.mobs[0] = EncounterState.mob(snail)
	check(WorldProtocol.valid(data), "world accepts separate shell health")
	data.mobs[0][9] = 66.0
	check(not WorldProtocol.valid(data), "world rejects oversized shell HP")
	data.mobs[0][9] = -1.0
	check(not WorldProtocol.valid(data), "world rejects negative shell HP")
	data.mobs[0] = data.mobs[0].slice(0, 9)
	check(WorldProtocol.valid(data), "legacy nine-value encounter records remain valid")
	snail.set_shell_health(0)
	EncounterState.apply_mob(snail, data.mobs[0])
	check(snail.shell_health == 65, "legacy checkpoint restores intact shell")
