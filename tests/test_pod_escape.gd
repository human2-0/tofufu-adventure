extends SceneTree

class QuestInput extends PlayerCommandSource:
	var direction: float = 0.0
	var held: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move.x = direction
		command.jump_held = held
		command.attack_held = true # Combat must remain suppressed throughout confinement.
		return command

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var rules := PodEscapeRules.new()
	rules.step(0.01, 1, false)
	check(rules.pushes == 0, "early push is rejected")
	for i in 200:
		rules.step(1.0 / 60.0, 1, false)
	check(rules.pushes == 0, "holding a direction cannot farm pushes")
	rules.beat = 0.25
	rules.step(0, 0, false)
	rules.step(0, -1, false)
	check(rules.pushes == 0, "wrong direction is rejected")
	check(PodEscapeRules.new().pushes == 0, "quest state is per instance")
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	var player: Player = scene.get_node("Player")
	var source := QuestInput.new()
	player.add_child(source)
	player.command_source = source
	root.add_child(scene)
	await ticks(3)
	var opening: PodOpening = scene.opening
	check(opening.active and not player.is_physics_processing(), "opening holds the real actor")
	check(player.position.y > 2.5 and not scene.hud.visible, "game starts inside suspended pod")
	check(not scene.combat.active, "attack input cannot fight inside pod")
	# Feed edge commands against the actual running quest clock.
	for push in 4:
		source.direction = 0
		await ticks(1)
		while absf(opening.rules.cue_value() - 0.5) > 0.04:
			await ticks(1)
		source.direction = opening.rules.direction
		await ticks(1)
		source.direction = 0
		await ticks(1)
	check(opening.rules.stage == PodEscapeRules.Stage.SNAP, "four alternating pushes unlock stem")
	source.held = true
	await ticks(8)
	source.held = false
	await ticks(1)
	check(opening.rules.stage == PodEscapeRules.Stage.SNAP, "short charge retries without losing pushes")
	source.held = true
	await ticks(70)
	source.held = false
	await ticks(1)
	check(opening.rules.stage == PodEscapeRules.Stage.SNAP, "overcharge cannot snap stem")
	source.held = true
	await ticks(40)
	source.held = false
	await ticks(1)
	check(opening.rules.stage == PodEscapeRules.Stage.FALL, "timed release drops pod")
	await ticks(60)
	check(opening.rules.stage == PodEscapeRules.Stage.SPLIT, "landing unlocks seam")
	check(player.position.y < 0.3, "pod and actor reach ground together")
	source.held = true
	await ticks(40)
	source.held = false
	await ticks(1)
	check(opening.rules.stage == PodEscapeRules.Stage.REVEAL, "timed push splits pod")
	await ticks(185)
	check(not opening.active and player.is_physics_processing(), "completion restores player movement")
	check(scene.hud.visible and scene.encounters.process_mode == Node.PROCESS_MODE_INHERIT, "completion restores sandbox")
	check(scene.camera.offset == Vector3(0, 14.3, 13.5), "camera restores exploration framing")
	check(opening.plant.left_shell.position.x < -0.8, "opened pod remains in world")
	var start := player.position.x
	source.direction = 1
	await ticks(15)
	check(player.position.x > start + 0.2, "Fufu can leave the pod and explore")
	scene.queue_free()
	await process_frame
	print("Pod escape: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame
