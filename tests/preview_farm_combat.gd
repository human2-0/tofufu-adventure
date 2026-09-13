extends SceneTree
## Render practice damage, outdoor packs and EXP feedback in the real game.

class QuietInput extends PlayerCommandSource:
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.aim = Vector2.UP
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var source := QuietInput.new()
	scene.get_node("Player").add_child(source)
	scene.get_node("Player").command_source = source
	root.add_child(scene)
	scene.hud.toggle_help()
	scene.hud.announce("")
	scene.cycle.set_process(false)
	scene.cycle.phase = 0.4
	scene.cycle._process(0)
	var mob: TrainingMob
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
			mob = child
	scene.player.position = scene.world.ground_point(19.3, 13.4, 0.1)
	scene.camera.position = scene.player.position + scene.camera.offset
	await ticks(20)
	scene.combat.strike(Vector2.UP, 1.0)
	await ticks(22)
	await capture("practice")
	for center in FarmCombatGrounds.CAMPS:
		scene.player.position = scene.world.ground_point(center.x, center.y + 3.5, 0.1)
		scene.player.velocity = Vector3.ZERO
		scene.camera.position = scene.player.position + scene.camera.offset
		await ticks(12)
		await capture("pack-" + str(int(center.y)))
	mob.target.damage(999)
	await ticks(6)
	await capture("experience")
	scene.queue_free()
	await process_frame
	quit()

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func capture(title: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/fufufarm-" + title + ".png")
