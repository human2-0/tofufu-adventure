extends SceneTree
## Focused authored boss rules, independent of dungeon reward wiring.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player_proxy := Node3D.new()
	player_proxy.position = Vector3(1.4, 0, 0)
	world.add_child(player_proxy)
	var boss := Dofufu.new()
	boss.combat_participants = 3
	boss.quarry = player_proxy
	world.add_child(boss)
	boss.set_physics_process(false)
	await physics_frame
	_check(is_equal_approx(boss.target.maximum, 1600.0), "party HP locks at encounter creation")
	_check(boss._sprite.texture != null and boss._katana.texture != null, "boss carries authored Nori appearance and katana")
	var strikes: Array[float] = []
	boss.attacked.connect(func(amount: float, _source: Vector3) -> void: strikes.append(amount))
	boss._physics_process(0.016)
	_check(boss.phase == Dofufu.Phase.WINDUP, "katana strike announces a windup")
	boss._physics_process(0.7)
	_check(strikes.size() == 1 and strikes[0] == Dofufu.COMBO_DAMAGE[0], "first strike resolves after telegraph")
	_check(boss.phase == Dofufu.Phase.RECOVERY, "strike grants recovery")
	boss._physics_process(0.25)
	boss._physics_process(0.016)
	_check(boss.phase == Dofufu.Phase.WINDUP, "combo next hit has a new windup")
	boss.target.damage(800.0)
	boss._physics_process(0.016)
	_check(boss.second_phase, "half health enters slam phase")
	boss.target.damage(10000.0)
	_check(boss.phase == Dofufu.Phase.DEAD, "death stops authored attack state")
	world.queue_free()
	await process_frame
	print("Dofufu: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
