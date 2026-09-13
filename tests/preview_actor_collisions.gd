extends SceneTree
## Render a real player walking/dashing into a snail, with capsule boundaries.

class ForwardInput extends PlayerCommandSource:
	var dash: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = Vector2.UP
		command.aim = Vector2.UP
		command.dash_direction = Vector2.UP
		command.dash_pressed = dash
		dash = false
		return command

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	var source := ForwardInput.new()
	scene.player.add_child(source)
	scene.player.command_source = source
	scene.weather.set_physics_process(false)
	scene.hud.announce("")
	var mob: TrainingMob = scene.encounters.mob_nodes[0]
	for actor: TrainingMob in scene.encounters.mob_nodes: actor.set_physics_process(false)
	scene.player.position = mob.position + Vector3(0, 0, 2)
	scene.camera.position = scene.player.position + scene.camera.offset
	scene.camera.offset *= 0.55
	outline(scene.player, 0.4, 1.1, Color(0.4, 0.85, 1, 0.25))
	outline(mob, 0.45, 1.0, Color(1, 0.65, 0.2, 0.25))
	for i in 65: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-collision-walk.png")
	source.dash = true
	for i in 12: await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-collision-dash.png")
	scene.queue_free()
	await process_frame
	quit()

func outline(actor: Node3D, radius: float, height: float, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	capsule.material = material
	mesh.mesh = capsule
	mesh.position.y = height * 0.5
	actor.add_child(mesh)
