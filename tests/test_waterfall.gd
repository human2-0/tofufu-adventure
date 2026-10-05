extends SceneTree
## Verify local presentation, collision alignment, weather recovery and bounded populations.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	await physics_frame
	game.player.set_physics_process(false)
	var falls := game.world.jungle.waterfall
	game.player.relocate(falls.global_position + Vector3(0, 0, -10))
	await physics_frame
	falls.present(1.0, game.player.position, 1.0, false, true)
	falls.spray._process(0.5)
	check(falls.spray.visible, "spray activates near the waterfall")
	check(falls.spray.drops.multimesh.instance_count == 112, "droplets stay bounded")
	check(falls.spray.mist.multimesh.instance_count == 24, "mist stays bounded")
	check(falls.wildlife.birds.size() == 6 and falls.wildlife.frogs.size() == 5, "rainforest population")
	check(falls.audio.roar.max_distance == 70.0, "water roar is positional with finite reach")
	check(falls.audio.roar.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "continuous waterfall sound")
	var ray := PhysicsRayQueryParameters3D.create(falls.global_position + Vector3.UP * 8, falls.global_position + Vector3.DOWN * 5, 1)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and absf(hit.position.y - 1.30) < 0.06, "basin collision matches authored ground")
	check(falls.global_position.y - hit.position.y < 0.4, "pool remains shallow and walkable")
	falls.wildlife.raining = true
	falls.wildlife._process(0.1)
	check(not falls.wildlife.butterflies[0].visible, "butterflies shelter during rain")
	var sky := game.cycle.sky_effects
	sky.tropical_blend = 1.0
	sky.present(1, 0.45, 1.0, 1.0)
	sky.present(1, 0.45, 1.0, 0.6)
	check(sky.rainbow_remaining > 0 and sky.material.get_shader_parameter("rainbow") > 0, "rainbow follows clearing daytime rain")
	sky.present(45, 0.45, 1.0, 0)
	check(sky.material.get_shader_parameter("rainbow") == 0.0, "rainbow fades away")
	sky.present(1, 0.0, 0, 1.0)
	sky.present(60, 0.0, 0, 0.0)
	check(sky.rainbow_remaining > 0 and sky.material.get_shader_parameter("rainbow") == 0.0, "night showers wait for sunlight")
	sky.present(1, 0.35, 0.8, 0.0)
	check(sky.material.get_shader_parameter("rainbow") > 0.0, "dawn reveals a bow after night showers")
	falls.present(5, Vector3.ZERO, 1, false, true)
	falls.spray._process(0.1)
	check(not falls.spray.visible and falls.audio.roar.volume_db == -80, "distant presentation is dormant and silent")
	game.queue_free()
	await process_frame
	print("Waterfall sanctuary: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
