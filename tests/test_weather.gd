extends SceneTree
## Weather outcomes, persistence, replica authority, and optional rendered previews.

var failures: int = 0
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	scene = load("res://game/app/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.weather.set_physics_process(false)
	scene.cycle.set_process(false)
	scene.player.set_physics_process(false)
	scene.camera.set_physics_process(false)
	for mob: TrainingMob in scene.encounters.mob_nodes:
		mob.set_physics_process(false)
	scene.player.position = scene.world.ground_point(-26, 7, 0.1)
	scene.camera.position = scene.player.position + scene.camera.offset
	scene.cycle.phase = 0.4
	scene.hud.toggle_help()
	scene.hud.announce("")
	await physics_frame
	check(active_count() == 9, "dry population starts at nine")
	await capture("clear")
	scene.weather._physics_process(46.0)
	check(scene.weather.condition == WeatherCycle.Condition.OVERCAST, "clock advances into overcast")
	await capture("overcast")
	var mob: TrainingMob = scene.encounters.mob_nodes[0]
	mob.target.damage(30.0)
	var dead: TrainingMob = scene.encounters.mob_nodes[1]
	dead.target.damage(999)
	dead._physics_process(11.0)
	check(not dead.visible, "dry respawn is still pending at eleven seconds")
	scene.weather._physics_process(15.0)
	check(scene.weather.condition == WeatherCycle.Condition.RAIN, "clock advances into rain")
	check(mob.target.maximum == 90 and mob.target.current == 45, "rain strength preserves injury proportion")
	scene.weather.set_phase(0.4)
	check(mob.target.current == 45, "repeated weather state does not heal")
	dead._physics_process(4.01)
	check(dead.visible and dead.target.current == 90, "pending respawn accelerates with rain")
	for reserve: TrainingMob in scene.encounters.mob_nodes.slice(9):
		reserve._physics_process(7.9)
		check(not reserve.visible, "rain recruits wait for respawn")
		reserve._physics_process(0.11)
	check(active_count() == 15, "rain increases population to fifteen")
	var hits: Array[float] = []
	mob.attacked.connect(func(amount: float, _source: Vector3) -> void: hits.append(amount))
	mob.position = mob._home
	scene.player.position = mob.position + Vector3(0, 0, 1.0)
	mob._windup = 0.01
	mob._rest = 0.0
	mob._choose_direction(0.02)
	check(hits == [18.0], "real rain strike emits increased damage")
	await capture("rain")
	var saved := AdventureSnapshot.capture(scene, "Weather", 10)
	check(SaveStore.valid(saved), "rainy solo save validates")
	var snapshot := CoopWorld.capture(scene)
	check(WorldProtocol.valid(snapshot), "rainy world snapshot validates")
	var encoded: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	var replica: Node3D = load("res://game/app/main.tscn").instantiate()
	replica.play_opening = false
	root.add_child(replica)
	CoopWorld.disable_simulation(replica)
	CoopWorld.apply(replica, encoded, true)
	check(not replica.weather.is_physics_processing(), "guest cannot advance weather")
	check(replica.weather.condition == WeatherCycle.Condition.RAIN, "guest receives rain")
	check(replica.encounters.mob_nodes[9].visible and replica.encounters.mob_nodes[0].target.maximum == 90, "guest receives reserves and strength")
	var before: float = replica.encounters.mob_nodes[0].target.current
	CoopWorld.apply(replica, encoded, true)
	check(replica.encounters.mob_nodes[0].target.current == before, "repeated snapshots preserve health")
	var invalid := encoded.duplicate(true)
	invalid.weather_phase = "rain"
	check(not WorldProtocol.valid(invalid), "malformed weather rejected")
	invalid = encoded.duplicate(true)
	invalid.weather_phase = 2.0
	check(not WorldProtocol.valid(invalid), "out-of-range weather rejected")
	scene.weather.set_phase(0.8)
	check(active_count() == 9 and mob.target.maximum == 60 and mob.target.current == 30, "dry weather retires extras and restores normal strength")
	check(scene.encounters.mob_nodes[9].target.current == 0, "retired reserves cannot be damaged for loot")
	AdventureSnapshot.restore(scene, saved)
	check(scene.weather.condition == WeatherCycle.Condition.RAIN, "solo load restores rain")
	var legacy := snapshot.duplicate(true)
	legacy.erase("weather_phase")
	legacy.mobs.resize(9)
	for row: Array in legacy.mobs: row[6] = minf(row[6], 60)
	check(WorldProtocol.valid(legacy), "legacy nine-mob checkpoints validate")
	CoopWorld.apply(replica, legacy, true)
	check(replica.weather.condition == WeatherCycle.Condition.CLEAR and not replica.encounters.mob_nodes[9].visible, "legacy checkpoints restore clear weather and dormant reserves")
	replica.queue_free()
	scene.weather.set_phase(0.9)
	scene.weather._physics_process(19.0)
	check(scene.weather.condition == WeatherCycle.Condition.CLEAR, "weather wraps safely")
	await capture("clearing")
	scene.queue_free()
	await process_frame
	print("Weather, rain populations, strength, saves and replicas: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func active_count() -> int:
	return scene.encounters.mob_nodes.filter(func(mob: TrainingMob) -> bool: return mob.visible).size()

func capture(title: String) -> void:
	if DisplayServer.get_name() == "headless": return
	scene.cycle._process(4.0)
	scene.weather_view._process(3.0)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-weather-" + title + ".png")
