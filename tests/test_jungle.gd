extends SceneTree
## Real collision checks for independent character access and the southern biome crossing.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var scene = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.player.set_physics_process(false)
	await physics_frame
	await physics_frame
	var actor: Player = scene.player
	var progress: CharacterProgress = scene.progression.progress
	var start := Transform3D(Basis.IDENTITY, Vector3(0, 6, 210))
	progress.award_experience(CharacterProgress.threshold(8, true) - 1)
	check(progress.level() == 7, "threshold setup")
	check(not actor.test_move(start, Vector3(0, 0, 9)), "test world leaves jungle open at level seven")
	var high := start
	high.origin.y = 18
	check(not actor.test_move(high, Vector3(0, 0, 9)), "jump crosses the open test route")
	var friend := load("res://game/player/player.tscn").instantiate() as Player
	scene.add_child(friend)
	friend.set_physics_process(false)
	friend.position = Vector3(0, 10, 0)
	var remote := CoopActor.new()
	remote.actor = friend
	remote.authority = true
	scene.add_child(remote)
	progress.award_experience(1)
	check(not friend.test_move(start, Vector3(0, 0, 9)), "friends can cross the open test route")
	check(not actor.test_move(start, Vector3(0, 0, 9)), "level eight can enter immediately")
	check(not actor.test_move(Transform3D(Basis.IDENTITY, Vector3(0, 6, 224)), Vector3(0, 0, -9)), "eligible actor can return")
	check(is_equal_approx(JungleTerrain.height_at(0, 216, scene.world.desert), DesertTerrain.height_at(0, 216, scene.world.terrain)), "terrain seam matches")
	for at in [Vector3(0, 20, 224), Vector3(20, 20, 270), Vector3(-40, 20, 314)]:
		var ray := PhysicsRayQueryParameters3D.create(at, at + Vector3.DOWN * 30, 1)
		check(not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "jungle has collision ground")
	progress.restore({})
	check(not actor.test_move(start, Vector3(0, 0, 9)), "restoring lower level keeps test world open")
	if DisplayServer.get_name() != "headless":
		scene.hud.visible = false
		scene.encounters.process_mode = Node.PROCESS_MODE_DISABLED
		scene.cycle.set_process(false)
		scene.cycle.phase = 0.4
		scene.cycle._process(0)
		var camera: Camera3D = scene.get_node("Camera3D")
		camera.set_physics_process(false)
		var targets := [Vector3(0, 3, 218), Vector3(0, 2, 286), Vector3(-40, 4, 314)]
		for i in targets.size():
			camera.position = targets[i] + (Vector3(-21, 12, 17) if i == 0 else Vector3(10, 24, 26))
			camera.look_at(targets[i])
			for frame in 8: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/jungle-%d.png" % i)
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
