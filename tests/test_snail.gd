extends SceneTree
## Actual damage feedback plus mirrored animation and timed effect regression.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.encounters.set_physics_process(false)
	for mob in scene.encounters.mob_nodes:
		mob.set_physics_process(false)
	scene.player.set_physics_process(false)
	scene.camera.set_physics_process(false)
	scene.hud._smear.set_process(false)
	var sprite := SnailVisuals.new()
	root.add_child(sprite)
	for direction in 8:
		var angle := direction * PI / 4.0
		var motion := Vector3(sin(angle), 0, cos(angle))
		sprite.present(motion, motion, 0.0, 0.0)
		assert(sprite.frame / 5 == mini(direction, 8 - direction))
		assert(sprite.flip_h == (direction > 4))
		sprite.present(Vector3.ZERO, motion, 0.65, 0.0)
		assert(sprite.texture == SnailVisuals.ATTACK)
		sprite.present(Vector3.ZERO, motion, 0.01, 0.0)
		sprite.present(Vector3.ZERO, motion, 0.0, 0.0)
		assert(sprite.frame % 5 == 3)
		sprite.present(Vector3.ZERO, motion, 0.0, 0.5)
		assert(sprite.texture == SnailVisuals.IDLE)
	sprite.queue_free()
	var center: Vector2 = FarmCombatGrounds.CAMPS[0]
	scene.player.position = scene.world.ground_point(center.x, center.y + 3.0, 0.1)
	scene.camera.position = scene.player.position + scene.camera.offset
	scene.hud.toggle_help()
	scene.hud.announce("")
	var source: Vector3 = scene.player.global_position + Vector3.FORWARD
	scene.health.invulnerability = 0.0
	scene.player.motor.is_dashing = true
	scene.encounters._hurt_player(12.0, source)
	assert(scene.hud._smear.remaining == 0.0)
	scene.player.motor.is_dashing = false
	scene.combat.equipment.guarding = true
	scene.combat.equipment.facing = Vector2.UP
	scene.encounters._hurt_player(12.0, source)
	assert(scene.hud._smear.remaining == 0.0)
	scene.combat.equipment.guarding = false
	await capture("clean")
	scene.encounters._hurt_player(12.0, source)
	assert(scene.hud._smear.remaining == 1.6)
	await capture("hit")
	scene.hud._smear._process(0.8)
	assert(scene.hud._smear.visible)
	await capture("fading")
	scene.hud._smear._process(0.81)
	assert(not scene.hud._smear.visible)
	await capture("cleared")
	scene.queue_free()
	await process_frame
	print("Snail directions, attack, dodge/guard and smear expiry: PASS")
	quit()

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/snail-" + label + ".png")
