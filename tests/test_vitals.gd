extends SceneTree
var failures: int = 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var rules := VitalRules.new()
	check(rules.maximum == 100.0, "level one starts with 100 SP")
	rules.set_level(3)
	check(is_equal_approx(rules.maximum, 104.04), "SP grows by compounded two percent")
	check(rules.spend(25.0), "special spends stamina")
	var before := rules.current
	rules.confirmed_hit()
	check(is_equal_approx(rules.current - before, 1.0404), "normal hit restores one percent of maximum")
	before = rules.current
	rules.confirmed_hit(false)
	check(rules.current == before, "special hits do not refund stamina")
	check(rules.step(29.0) == 0.0, "no healing before thirty seconds")
	check(is_equal_approx(rules.step(2.0), 0.02), "only time after combat timeout heals")
	rules.engage()
	check(rules.step(1.0) == 0.0, "new threat interrupts recovery")
	rules.current = 10
	check(not rules.spend(25) and rules.current == 10, "insufficient stamina cannot pay or go negative")
	rules.step(1)
	check(is_equal_approx(rules.current, 15.202), "stamina regenerates during battle")
	var motor := PlayerMotor.new(PlayerTuning.new())
	motor.spend_stamina = rules.spend
	var command := PlayerCommand.new()
	command.dash_pressed = true
	rules.current = 0
	motor.step(command, Vector3.ZERO, true, 0.016)
	check(not motor.is_dashing and motor.cooldown_remaining == 0, "failed dash starts no cooldown")
	rules.current = 20
	motor.step(command, Vector3.ZERO, true, 0.016)
	check(motor.is_dashing and rules.current == 5, "dash deducts fifteen once")
	var game := preload("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.progression.progress.award_experience(CharacterProgress.threshold(3, true))
	check(is_equal_approx(game.health.maximum, 110.25), "HP compounds five percent per level")
	game.health.current = 50
	game.player.threatened.emit()
	game.progression._step_vitals(PlayerCommand.new(), 29)
	check(game.health.current == 50, "targeted player cannot recover health")
	game.progression._step_vitals(PlayerCommand.new(), 2)
	check(is_equal_approx(game.health.current, 52.205), "health recovers gradually after delay")
	game.combat.vitals.current = 40
	game.combat._damage(game.encounters.dummy_nodes[0].target)
	check(is_equal_approx(game.combat.vitals.current, 41.0404) and game.combat.vitals.combat_remaining == 30, "real dummy hit restores SP and starts combat")
	var mob: TrainingMob = game.encounters.mob_nodes[0]
	mob.position = game.player.position + Vector3(4, 0, 0)
	mob._home = mob.position
	mob.protected_area = Rect2()
	game.combat.vitals.combat_remaining = 0
	mob._choose_direction(0.016)
	check(game.combat.vitals.combat_remaining == 30, "mob chase starts combat before an attack lands")
	game.combat.vitals.current = 20
	game.combat.equipment.guarding = true
	game.combat.equipment.facing = Vector2.DOWN
	check(game.combat.equipment.defend(game.player.global_position + Vector3.BACK, 12), "directional defence succeeds")
	check(game.combat.vitals.current == 8, "guard pays incoming damage in SP")
	check(not game.combat.equipment.defend(game.player.global_position + Vector3.BACK, 12), "exhausted guard lets hit through")
	game.combat.vitals.current = 50
	var normal: Vector3 = game.health.reflection_normal(Vector3.FORWARD, game.player.global_position + Vector3.UP * 0.7, true, 20)
	check(not normal.is_zero_approx() and game.combat.vitals.current == 30, "projectile guard spends actual damage once")
	game.combat.vitals.current = 8
	game.combat.equipment.guarding = false
	game.combat._start_tornado(Vector2.DOWN)
	check(not game.combat.active and game.combat.vitals.current == 8, "spin rejected without twenty five SP")
	game.combat.vitals.current = 60
	game.combat._start_tornado(Vector2.DOWN)
	check(game.combat.active and game.combat.vitals.current == 35, "spin costs twenty five SP")
	game.combat.reset()
	game.combat.equipment.pod_selected = true
	game.combat.podburst.fire(game.combat, Vector2.DOWN)
	check(game.combat.vitals.current == 10, "crescent costs twenty five SP")
	var snapshot := AdventureSnapshot.capture(game, "Vitals", 0)
	check(SaveStore.valid(snapshot), "higher-level save validates")
	game.combat.vitals.current = 0
	AdventureSnapshot.restore(game, snapshot)
	check(game.combat.vitals.current == 10, "stamina survives solo save")
	var member := CoopActor.new()
	member.actor = game.player
	member.combat = game.combat
	member.health = game.health
	member.progression = game.progression
	member.loadout = game.loadout
	member.inventory = game.inventory
	member.character_equipment = game.character_equipment
	var actor_state := member.capture()
	check(ExplorationProtocol.actor(actor_state), "level three health validates in co-op actor snapshot")
	actor_state.progression = []
	check(not ExplorationProtocol.actor(actor_state), "malformed progression rejected without conversion")
	member.free()
	check(ExplorationProtocol.combat(CombatState.capture(game.combat)), "vitals validate in combat snapshot")
	check(not ExplorationProtocol.vitals({"stamina": NAN, "combat_remaining": 0}), "nonfinite SP rejected")
	if "--render" in OS.get_cmdline_user_args():
		root.size = Vector2i(960, 540)
		game.hud.show_stamina(game.combat.vitals.current, game.combat.vitals.maximum, 30.0)
		for frame in 10: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/tofufu-vitals-combat.png")
	game.queue_free()
	await process_frame
	print("Vitals: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
