extends SceneTree
## Visual preview script for testing compact chat, fist hit rate, and action HUD.

class ScriptedPunch extends PlayerCommandSource:
	func sample(_position: Vector3) -> PlayerCommand:
		var cmd := PlayerCommand.new()
		cmd.weapon_slot = 2
		return cmd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	var source := ScriptedPunch.new()
	scene.get_node("Player").add_child(source)
	scene.get_node("Player").command_source = source
	root.add_child(scene)

	scene.player.position = scene.world.ground_point(19.3, 13.4, 0.1)
	scene.camera.position = scene.player.position + scene.camera.offset
	for mob in scene.encounters.mob_nodes: mob.set_physics_process(false)

	# Ensure fists are selected and show hit rate
	scene.combat.equipment.step(Vector2.DOWN, false, false, false, false, 2, 0.016)

	for frame in 20:
		await physics_frame
		await process_frame

	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("/tmp/tofufu-fist-compact-chat.png") == OK)

	scene.queue_free()
	await process_frame
	quit()
