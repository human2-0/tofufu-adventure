extends SceneTree
## Actual Godot jungle, five-view poses, rift, worn/FPP paws and both UI locales.

const OUT := "res://.codex/visualizations/2026/10/16/bengal-charge/"
var game: AdventureGame

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GamePreferences.install_translations(self)
	TranslationServer.set_locale("en")
	root.size = Vector2i(1600, 900)
	root.content_scale_size = root.size
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.weather.set_physics_process(false)
	game.cycle.set_process(false)
	game.cycle.phase = 0.4
	game.cycle._process(0)
	game.hud.hide()
	game.chat.view.hide()
	game.player.hide()
	for mob in game.encounters.mob_nodes:
		mob.set_physics_process(false)
		mob.set_process(false)
		mob.hide()
	var center := game.world.ground_point(0, 251, 0.9)
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.size = 22
	game.camera.position = center + Vector3(0, 13, 20)
	game.camera.look_at(center)
	var forward := Vector3(0, 0, 1)
	for row in 2:
		for column in 5:
			var cat := game.encounters.mob_nodes[59 + row * 5 + column] as BengalMonster
			cat.show()
			cat.position = game.world.ground_point((column - 2) * 3.8, 246 + row * 7, 0.1)
			cat.facing = forward.rotated(Vector3.UP, column * PI / 4)
			cat.art.present(cat.facing, row == 1, 0, 0, 0)
	await capture("five-angles-run-a")
	for index in range(59, 69):
		var cat := game.encounters.mob_nodes[index] as BengalMonster
		cat.art.present(cat.facing, index >= 64, 0, 0.25 if index < 64 else 0, 0.12)
	await capture("five-angles-claw-run-b")
	for index in range(59, 71):
		var cat := game.encounters.mob_nodes[index] as BengalMonster
		cat.position = cat._home
		cat.show()
		cat.set_process(true)
	game.player.show()
	game.progression.progress.award_experience(CharacterProgress.threshold(15, true))
	game.hud._popup.hide()
	game.hud._notice_time = 0
	game.character_equipment.set_slot("combat_1", ItemStack.new(BengalPawsItem.create(), 1))
	game.inventory.set_slot(0, ItemStack.new(BengalPawsItem.create(), 1))
	var cat := game.encounters.mob_nodes[59] as BengalMonster
	game.player.position = cat.position + Vector3.RIGHT * 2.5
	game.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	game.camera.fov = 55
	game.camera.position = game.player.position + Vector3(3.8, 3.3, 5)
	game.camera.look_at(game.player.position + Vector3.UP * 0.7)
	var command := PlayerCommand.new()
	command.aim = Vector2.DOWN
	command.face_aim = true
	game.player.visuals.present(command, Vector3.ZERO, true, false, 0.016, 0, 0)
	await capture("held-paws")
	game.world_items.spawn_mob_loot(BengalPawsItem.ID, game.player.position + Vector3(-1, 0, 1))
	await capture("ground-drop")
	game.player.position = cat.position - Vector3.BACK * 4.5
	game.camera.position = game.player.position + Vector3(4.8, 3.6, 6)
	game.camera.look_at(game.player.position + Vector3(0, 0.7, 2))
	game.combat.targets = [cat.target]
	game.combat.claws.target_point = cat.target.global_position
	game.combat.equipment.facing = Vector2.DOWN
	game.combat.step(Vector2.DOWN, false, 1.6, Vector2.ZERO, false, true)
	await capture("charging-claws")
	game.combat.step(Vector2.DOWN, false, 0.4, Vector2.ZERO, false, true)
	game.player.position += game.combat.claws.velocity(Vector3.ZERO, true, 0.08) * 0.08
	game.combat.step(Vector2.DOWN, false, 0.08, Vector2.ZERO, false, true)
	game.player.visuals.present(command, Vector3.BACK * 20, true, true, 0.016, 0, 0)
	await capture("dash-trail")
	var remaining := game.combat.claws.remaining
	game.player.position += game.combat.claws.velocity(Vector3.ZERO, true, remaining) * remaining
	game.combat.step(Vector2.DOWN, false, remaining, Vector2.ZERO, false, true)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "reality-rift.png")
	for child in game.combat.get_children():
		if is_instance_valid(child) and child is BengalRiftEffect:
			child.set_process(false)
			for sample in [Vector2(0.07, 0), Vector2(0.20, 1), Vector2(0.45, 2), Vector2(0.86, 3)]:
				child.age = sample.x
				child.present()
				await capture("super-claw-phase-%d" % int(sample.y))
			child.set_process(true)
	await capture("paralysis")
	game.hud.show()
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		game.inventory_window.open()
		await process_frame
		var button: InventorySlotButton = game.inventory_window._eq_buttons["combat_1"]
		button.grab_focus()
		game.inventory_window._tooltip.inspect(button, func() -> ItemStack: return game.character_equipment.get_slot("combat_1"))
		await capture("inventory-" + locale)
		game.inventory_window.close()
	game.player.position = cat.position - Vector3.BACK * 3.5
	game.shooting_view.cycle_mode()
	game.shooting_view.cycle_mode()
	game.camera._process(0)
	await capture("first-person-paws")
	game.combat.claws.cooldown = 0
	game.combat.equipment._punch_time = 0
	game.combat.claws.fire(game.combat, Vector2.DOWN)
	game.combat.claws.charge = 1.6
	await capture("first-person-charging")
	game.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")
