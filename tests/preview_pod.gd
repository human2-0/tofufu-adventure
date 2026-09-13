extends SceneTree
## Actual rendered quest milestones. Uses the same timed input path as play.

class PreviewInput extends PlayerCommandSource:
	var direction: float = 0
	var held: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move.x = direction
		command.jump_held = held
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	var player: Player = scene.get_node("Player")
	var source := PreviewInput.new()
	player.add_child(source)
	player.command_source = source
	root.add_child(scene)
	await ticks(20)
	await capture("hanging")
	for i in 4:
		while absf(scene.opening.rules.cue_value() - 0.5) > 0.04:
			await ticks(1)
		source.direction = scene.opening.rules.direction
		await ticks(1)
		source.direction = 0
		await ticks(1)
	await capture("stem")
	source.held = true
	await ticks(40)
	await capture("charge")
	source.held = false
	await ticks(62)
	await capture("landed")
	source.held = true
	await ticks(40)
	source.held = false
	await ticks(50)
	await capture("escape")
	await ticks(160)
	await capture("world")
	scene.queue_free()
	await process_frame
	quit()

func ticks(count: int) -> void:
	for tick in count:
		await physics_frame
		await process_frame

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-pod-" + label + ".png")
