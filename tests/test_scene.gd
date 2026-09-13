extends SceneTree

class ScriptedInput extends PlayerCommandSource:
	var next_command: PlayerCommand = PlayerCommand.new()

	func sample(_position: Vector3) -> PlayerCommand:
		var result := next_command
		next_command = PlayerCommand.new()
		return result

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var player: Player = scene.get_node("Player")
	var source := ScriptedInput.new()
	player.add_child(source)
	player.command_source = source
	root.add_child(scene)
	var hud: HUD = scene.get_node("HUD")
	var camera: CameraFollow = scene.get_node("Camera3D")
	check(camera.target == player, "camera has explicit player target")
	check(player.dash_cooldown_updated.is_connected(hud.show_dash_cooldown), "HUD is wired by composition root")
	await ticks(30)
	check(player.is_on_floor(), "player collides with world floor")
	check(absf(player.position.y) < 0.1, "player stays on floor")
	var start := player.position
	for tick in 12:
		source.next_command.move = Vector2.RIGHT
		await ticks(1)
	check(player.position.x > start.x + 0.2, "injected command moves real body")
	source.next_command.jump_pressed = true
	for tick in 45:
		source.next_command.jump_held = true
		await ticks(1)
	check(player.is_on_floor() and player.motor.jump_charge == 1.0, "holding fully charges without leaving floor")
	await ticks(3)
	check(player.position.y > 0.1, "jump lifts real body off floor")
	source.next_command.dash_pressed = true
	source.next_command.dash_direction = Vector2.RIGHT
	await ticks(2)
	check(player.motor.is_dashing, "dash triggers through command source")
	check(hud.dash_bar.value < 100.0, "HUD shows cooldown")
	await ticks(70)
	check(not player.motor.is_dashing and player.motor.cooldown_remaining == 0.0, "dash and cooldown finish")
	hud.show_dash_cooldown(0.0, 0.0)
	check(hud.dash_bar.value == 100.0, "zero-duration cooldown is safe")
	scene.queue_free()
	await process_frame
	print("Scene integration tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame
