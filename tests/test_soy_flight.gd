extends SceneTree
## One visible bean per shot, continuous muzzle departure in FPP ADS and overhead.
var failures: int = 0

func _initialize() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var game := load("res://game/app/main.tscn").instantiate() as Node3D
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.position = Vector3(0, 25, 0)
	game.character_equipment.set_slot("combat_1", ItemStack.new(InventoryItem.weapon("soy_gun"), 1))
	game.loadout.select(1)
	var gun: SoyGun = game.combat.gun
	gun.spread_multiplier = 0
	for first_person in [false, true]:
		if first_person:
			game.shooting_view.cycle_mode()
			game.shooting_view.cycle_mode()
		game.camera.yaw = 0
		game.camera.pitch = 0
		for ads in [false, true]:
			gun.aiming = ads
			var command := PlayerCommand.new()
			command.aim = Vector2.UP
			game.player.visuals.attack_facing = Vector2.UP
			for frame in 12:
				game.player.visuals.present(command, Vector3.ZERO, true, false, 1.0 / 60)
				await process_frame
			gun.cooldown = 0
			var sequence := gun.shot_sequence
			gun.step(true, ads, Vector2.UP, Vector3(0, 25.8, -30), 1.0 / 60)
			var beans := gun.get_children().filter(func(n: Node) -> bool: return n is SoyProjectile)
			check(beans.size() == 1 and gun.shot_sequence == sequence + 1, "one bean per trigger in each view")
			var bean := beans[0] as SoyProjectile
			bean.set_physics_process(false)
			bean.set_process(false)
			var muzzle := game.shooting_view._gun_muzzle() as Vector3
			check(bean._sprite.global_position.distance_to(muzzle) < 0.001, "shot starts at visible muzzle")
			# Render-only frames must not pull a stationary shot toward another origin.
			var launch := bean.visual_position(0)
			for hz in [30.0, 60.0, 144.0]: bean._process(1.0 / hz)
			check(bean._sprite.global_position.is_equal_approx(launch), "render rate does not change muzzle correction")
			var previous := launch
			for tick in 15:
				bean._physics_process(1.0 / 60)
				check(bean.visual_position(0).distance_to(previous) < 0.001, "physics segments join without a second origin")
				for part in 4:
					var at := bean.visual_position((part + 1) / 4.0)
					check(at.distance_to(previous) < 0.4, "bean advances smoothly between rendered frames")
					previous = at
			check(bean.visual_position(1).distance_to(bean.global_position) < 0.001, "visual converges to collision flight")
			bean.free()
	game.queue_free()
	await process_frame
	print("Soy flight: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
