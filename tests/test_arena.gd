extends SceneTree
## Real perimeter collisions, fast cover contact and bounded arena UI intent.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var arena := FarmDuelArena.new()
	world.add_child(arena)
	arena.build(func(x: float, z: float) -> Vector3: return Vector3(x, 0, z))
	var actor: Player = load("res://game/player/player.tscn").instantiate()
	world.add_child(actor)
	actor.set_physics_process(false)
	var trials: Array[Vector3] = [Vector3(90, 0.05, 40), Vector3(50, 0.05, 40), Vector3(66, 0.05, 49), Vector3(66, 0.05, 17)]
	var pushes: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]
	for index in trials.size():
		actor.position = trials[index]
		for tick in 12:
			await physics_frame
			actor.velocity = pushes[index] * 80 + Vector3.DOWN
			actor.move_and_slide()
		check(arena.contains_arena(actor.position), "physical wall blocks sustained outward movement on side %d" % index)
		check(actor.position.distance_to(trials[index]) < 1.0, "wall contact keeps position near edge without spawn reset")
	var bean := SoyProjectile.new()
	bean.shooter = actor
	bean.velocity = Vector3.RIGHT * 120
	world.add_child(bean)
	bean.position = Vector3(66, 1.0, 33)
	for tick in 5:
		await physics_frame
		await process_frame
	check(not is_instance_valid(bean), "120m/s bullet is absorbed by central cover without tunnelling")
	var agreement := CoopDuelAgreement.new()
	agreement.reset()
	check(not agreement.accept(0, "soy_gun", ""), "one fighter cannot start a match")
	check(not agreement.accept(1, "sotjet", "knife"), "mismatched ranged choices cannot start a match")
	check(agreement.accept(0, "sotjet", ""), "both ready on same mode preserves independent melee choices")
	check(not DuelProtocol.valid_action({"action": "accept", "ranged": "soy_gun", "melee": "forged", "sequence": 1, "match": 1}), "forged weapon choices are rejected")
	check(not DuelProtocol.valid_action({"action": "leave", "ranged": "soy_gun", "melee": "", "sequence": -1, "match": 1}), "negative action sequences are rejected")
	var canvas := CanvasLayer.new()
	root.add_child(canvas)
	var hud := ArenaHUD.new()
	canvas.add_child(hud)
	var intents: Array[String] = []
	hud.action_requested.connect(func(action: String, _r: String, _m: String) -> void: intents.append(action))
	hud.present({"phase": "fight", "match": 1, "participant": true, "names": ["You", "Opponent"], "scores": [1, 2]})
	hud._leave()
	check(intents.is_empty(), "first surrender click requires deliberate confirmation")
	hud._leave()
	check(intents == ["leave"], "second surrender click emits one intent")
	hud.present({"phase": "idle"})
	check(not hud.visible, "arena UI disappears after match cleanup")
	world.queue_free()
	canvas.queue_free()
	await process_frame
	print("Arena: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
