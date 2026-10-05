extends SceneTree
## Momentum, independent endurance, charged costs and live/save boundaries.

var failures: int = 0
const DT: float = 1.0 / 60.0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_rules()
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.combat.vitals.current = 0.0
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	command.run_held = true
	var velocity := Vector3.ZERO
	for tick in 60: velocity = game.player.motor.step(command, velocity, true, DT)
	check(velocity.x > game.player.tuning.walk_speed and game.combat.vitals.current == 0.0, "running spends its own reserve while combat SP is empty")
	game.hud.show_run_stamina(50, 100, false)
	check(not game.hud._run_meter.visible, "healthy running reserve stays hidden")
	game.hud.show_run_stamina(29, 100, false)
	check(game.hud._run_meter.visible, "reserve below thirty percent becomes visible")
	game.hud.show_run_stamina(35, 100, false)
	check(game.hud._run_meter.visible, "recovering meter does not flicker around low threshold")
	game.hud.show_run_stamina(46, 100, false)
	check(not game.hud._run_meter.visible, "recovered reserve hides again")
	_attacks(game.combat)
	await _winter(game)
	game.player.motor.endurance.current = 12
	game.player.motor.endurance.exhausted = true
	var saved := AdventureSnapshot.capture(game, "Heavy movement", 0)
	check(SaveStore.valid(saved), "running state validates in solo save")
	game.player.motor.endurance.reset()
	AdventureSnapshot.restore(game, saved)
	check(game.player.motor.endurance.current == 12 and game.player.motor.endurance.exhausted, "saving does not refill exhausted running stamina")
	saved.erase("endurance")
	AdventureSnapshot.restore(game, saved)
	check(game.player.motor.endurance.current == 100, "legacy solo saves default to full running reserve")
	saved.endurance = {"current": NAN, "rest": 0, "exhausted": false}
	check(not SaveStore.valid(saved), "save rejects nonfinite running state")
	var member := CoopActor.new()
	member.actor = game.player
	member.combat = game.combat
	member.health = game.health
	member.progression = game.progression
	member.loadout = game.loadout
	member.inventory = game.inventory
	member.character_equipment = game.character_equipment
	game.player.motor.endurance.current = 22
	var state := member.capture()
	check(ExplorationProtocol.actor(state) and state.endurance.current == 22, "co-op actor snapshot carries bounded separate reserve")
	CoopActorReplica.accept_view(member, state)
	check(game.player.motor.endurance.current == 22, "replica accepts host running reserve")
	state.endurance.current = 101
	check(not ExplorationProtocol.actor(state), "peer cannot supply oversized running stamina")
	state.erase("endurance")
	check(ExplorationProtocol.actor(state), "legacy actor checkpoint remains readable")
	var remote := RemotePlayerInput.new()
	var packet := CoopValues.input(command, 1, 0)
	check(ExplorationProtocol.valid_input(packet), "run intent validates")
	remote.accept(CoopValues.command(packet), 1)
	check(remote.sample(Vector3.ZERO).run_held and remote.sample(Vector3.ZERO).run_held, "run hold survives remote ticks without a new packet")
	remote._last_received = Time.get_ticks_msec() - 300
	check(not remote.sample(Vector3.ZERO).run_held, "expired input cannot continue running")
	packet.run_held = "yes"
	check(not ExplorationProtocol.valid_input(packet), "run intent must be boolean")
	remote.free()
	member.free()
	game.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("Heavy movement: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _rules() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var command := PlayerCommand.new()
	command.move = Vector2.RIGHT
	var velocity := motor.step(command, Vector3.ZERO, true, DT)
	check(velocity.x < 0.3, "walk builds momentum gradually")
	velocity = Vector3(tuning.walk_speed, 0, 0)
	command.move = Vector2.LEFT
	velocity = motor.step(command, velocity, true, DT)
	check(velocity.x > 0, "reversing cannot instantly erase momentum")
	command.move = Vector2.ZERO
	var ground := motor.step(command, Vector3(4, 0, 0), true, DT)
	var air := motor.step(command, Vector3(4, 0, 0), false, DT)
	motor.surface_grip = 0.24
	var ice := motor.step(command, Vector3(4, 0, 0), true, DT)
	check(air.x > ground.x and ice.x > ground.x, "air and ice retain more momentum than firm ground")
	var endurance := RunEndurance.new()
	endurance.step(true, false, true, 1.0)
	check(endurance.current == 100, "holding run while stationary costs nothing")
	for tick in 360: endurance.step(true, true, true, DT)
	check(endurance.exhausted and not endurance.running, "continuous running exhausts and falls back to walking")
	endurance.step(true, true, true, 10.0)
	check(endurance.exhausted and not endurance.running, "holding run cannot bypass exhaustion lockout")
	endurance.step(false, false, true, DT)
	endurance.step(true, true, true, DT)
	check(endurance.running, "rest plus releasing run allows a fresh sprint")
	check(RunEndurance.new().current == 100, "reserves are per actor")

func _attacks(combat: PlayerCombat) -> void:
	for pod in [false, true]:
		combat.reset()
		combat.equipment.knife_owned = true
		combat.equipment.knife_selected = true
		combat.equipment.pod_selected = pod
		combat.vitals.current = 25
		combat.strike(Vector2.DOWN, 1.0)
		check(combat.active and combat.vitals.current == 0, "fully charged knife/sword pays twenty five SP once")
		combat.strike(Vector2.DOWN, 1.0)
		check(combat.vitals.current == 0, "active strike cannot spend twice")
		combat.reset()
		combat.equipment.knife_selected = true
		combat.vitals.current = 24
		combat.strike(Vector2.DOWN, 1.0)
		check(not combat.active and combat.vitals.current == 24, "insufficient SP rejects power strike without free damage")
		combat.strike(Vector2.DOWN, 0.0)
		check(combat.active and combat.vitals.current == 24, "ordinary melee remains available with low SP")
	combat.reset()
	combat.equipment.knife_selected = true
	combat.vitals.current = 60
	combat.step(Vector2.DOWN, true, combat.tuning.charge_seconds + 0.1)
	check(combat.vitals.current == 60 and not combat.active, "holding a charged attack reserves no repeated cost")
	combat.step(Vector2.DOWN, false, DT)
	check(combat.active and combat.vitals.current == 35, "real held attack pays on release")
	combat.reset()

func _winter(game: AdventureGame) -> void:
	game.weather.set_physics_process(false)
	game.player.position = game.world.ground_point(44, -298)
	TerrainLocomotion.apply(game.player, game.world)
	check(game.player.motor.surface_grip < 0.3, "mirror ice has substantially less grip")
	game.player.position = game.world.ground_point(0, -280)
	TerrainLocomotion.apply(game.player, game.world)
	check(game.player.surface_speed == 0.9 and game.player.motor.surface_grip == 0.68, "snow slows footing with softer traction")
	game.weather.set_phase(0.45)
	for tick in 2: await physics_frame
	await process_frame
	game.weather_particles._process(3.0)
	check(game.weather_particles.winter and game.weather_particles._snow.visible, "winter precipitation is rendered snowfall")
	check(not game.weather_particles._rain.visible and not game.weather_particles._leaves.visible, "winter does not show rain streaks or summer leaves")
	check(game.weather_particles._snow.multimesh.instance_count == 576 and game.weather_particles._heights.size() == 144, "snow instances and moving cell cache stay bounded")
	var sample := game.weather_particles._snow.multimesh.get_instance_transform(0)
	var cell := game.weather_particles._center
	game.weather_particles._place(cell + Vector2i.RIGHT)
	game.weather_particles._place(cell)
	check(game.weather_particles._snow.multimesh.get_instance_transform(0) == sample, "overlapping snowfall cells stay stable")
	game.weather_particles.sheltered = true
	game.weather_particles._process(DT)
	check(not game.weather_particles._snow.visible, "snow stays outside sheltered interiors")
	game.weather_particles.sheltered = false
	game.player.position = game.world.ground_point(0, 0)
	for tick in 2: await physics_frame
	await process_frame
	game.weather_particles._process(3.0)
	check(not game.weather_particles._snow.visible and game.weather_particles._rain.visible, "leaving winter restores rain during the same shared weather spell")
