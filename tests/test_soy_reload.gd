extends SceneTree
## Reload readouts survive render callbacks; poses share the authority clock.
var failures: int = 0
var game: AdventureGame

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func frames() -> void:
	await process_frame
	await process_frame

func _run() -> void:
	root.size = Vector2i(1440, 900)
	game = load("res://game/app/adventure/main.tscn").instantiate() as AdventureGame
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.set_physics_process(false)
	game.player.position = game.world.ground_point(19.3, 14.3)
	game.loadout.select(2)
	var gun := game.combat.gun
	var view := game.shooting_view
	var hud := game.hud
	await frames()
	for shot in SoyGun.MAGAZINE_SIZE:
		gun.cooldown = 0.0
		gun.step(true, false, Vector2.UP, game.player.position + Vector3(0, 0.7, -20), 0.01)
	await frames()
	check(hud._charge_text.text.begins_with("RELOADING"), "render callbacks preserve the live reload text")
	check(is_zero_approx(hud._charge_bar.value), "reload bar starts empty")
	check(is_equal_approx(view.reticle.reload_remaining, 2.0), "reticle displays the live reload clock")
	var sequence := gun.shot_sequence
	gun.step(false, false, Vector2.UP, Vector3.ZERO, 1.0)
	await frames()
	check(is_equal_approx(hud._charge_bar.value, 50.0), "reload bar fills halfway after one second")
	check(is_equal_approx(view.reticle.reload_progress, 0.5), "aim ring agrees with the HUD")
	check(hud._charge_text.text.contains("1.0s"), "HUD shows the remaining time after releasing fire")
	check(gun.shot_sequence == sequence and gun.magazine == 0, "presentation does not shoot or refill early")
	var visual := gun.visual
	visual.refresh()
	check(visual.global_basis.x.dot(game.camera.global_basis.x) < 0.95, "world gun rolls into a reload pose")
	view.cycle_mode()
	view.cycle_mode()
	await frames()
	var overlay := view.weapon_view
	check(absf(overlay._rig.rotation.z) > 0.4, "first-person gun tilts while reloading")
	check(overlay._hands[1].position.x > -0.05, "support hand reaches toward the gun to reload")
	# Replica visuals read the existing snapshot timer without simulating outcomes.
	var snapshot := CombatState.capture(game.combat)
	var replica := PlayerCombat.new()
	replica.actor = game.player
	game.add_child(replica)
	CombatState.present(replica, snapshot, Vector2.UP)
	await frames()
	check(is_equal_approx(replica.gun.visual.reload_remaining, 1.0), "observer gun animates from the replicated reload timer")
	check(replica.gun.magazine == 0 and is_equal_approx(replica.gun.reload_remaining, 1.0), "replica presentation never advances the reload")
	replica.free()
	game.loadout.select(1)
	await frames()
	check(view.reticle.reload_remaining == 0.0, "switching to melee clears the reload indicator")
	game.loadout.select(2)
	gun.step(false, false, Vector2.UP, Vector3.ZERO, 1.0)
	await frames()
	check(gun.magazine == 9 and gun.reload_remaining == 0.0, "authority finishes the two-second reload")
	check(not hud._charge_text.text.begins_with("RELOADING") and hud._charge_text.text.contains("9 / 9"), "completion restores the ammo readout")
	check(view.reticle.reload_remaining == 0.0 and is_zero_approx(overlay._rig.rotation.z), "completion clears the aim ring and restores the gun pose")
	if "--preview" in OS.get_cmdline_user_args(): await _preview()
	game.queue_free()
	await frames()
	if failures == 0: print("Soy gun reload feedback checks passed")
	quit(1 if failures else 0)

func _preview() -> void:
	game.hud._notice_time = 0.0
	game.camera.yaw = 0.0
	game.camera.pitch = 0.0
	game.shooting_view.set_process_unhandled_input(false)
	game.shooting_view.cycle_mode()
	for mode in ["overhead", "shoulder", "first-person"]:
		for remaining in [2.0, 1.0, 0.0]:
			game.combat.gun.magazine = 0 if remaining > 0 else 9
			game.combat.gun.reload_remaining = remaining
			var command := PlayerCommand.new()
			command.aim = Vector2.UP
			for frame in 12:
				game.player.visuals.present(command, Vector3.ZERO, true, false, 0.016)
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/tofufu-reload-%s-%.0f.png" % [mode, remaining])
		game.shooting_view.cycle_mode()
