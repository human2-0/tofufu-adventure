extends SceneTree
## Native texture, compact bilingual confirmation and actual graphical result wiring.
const OUTPUT := "res://.codex/visualizations/2026/10/23/royale-loot"
var game: BattleRoyaleGame
var gallery: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _shot(name: String) -> void:
	for i in 6: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT).path_join(name + ".png"))

func _sizes(kind: String, refresh: Callable) -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			refresh.call()
			await create_timer(2).timeout
			await _shot("%s-%d-%s" % [kind, dimensions.x, locale])
			if kind == "results" and dimensions.x == 640:
				var scroll := game.match_view.results._stack.get_child(1) as ScrollContainer
				scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
				await _shot("results-details-640-%s" % locale)
				scroll.scroll_vertical = 0

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.theme = MenuStyle.make_theme()
	_gallery()
	await _sizes("chests", func() -> void: pass)
	gallery.free()
	var room := BattleRoom.new()
	root.add_child(room)
	room.options = [2, 1]
	room.practice()
	game = BattleRoyaleGame.new()
	game.preferences.path = "user://royale-loot-preview-%d.cfg" % Time.get_ticks_usec()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.local_input.enabled = false
	game.match_state.time = 13
	var loadout := game.combat.fighters[0].loadout
	loadout.inventory.set_slot(0, ItemStack.new(BattleItems.make(33), 2))
	game.pack_ui.show_bag()
	await _sizes("upgrade", func() -> void:
		game.pack_ui.bag.enhancement_confirmation.clear()
		game.pack_ui.bag.execute_transfer("inventory", 0, "equipment", "combat_2"))
	game.pack_ui.close()
	game.match_view.career = BattleCareer.new()
	game.match_view.career.path = "user://royale-loot-preview-career-%d.json" % Time.get_ticks_usec()
	game.match_view.career.xp = 90
	game.match_state.stats[0] = [325.0, 68.0, 6, 2, 185.0, 0.0]
	for slot in [1, 2]: game.match_state.hit(slot, 1000, 0)
	game.match_state.step(0.01)
	await _sizes("results", game._update_hud)
	game.queue_free()
	room.queue_free()
	await process_frame
	await process_frame
	print("Native chest / upgrade / results preview complete: ", ProjectSettings.globalize_path(OUTPUT))
	quit()

func _gallery() -> void:
	gallery = Node3D.new()
	root.add_child(gallery)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("243f40")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("e8f0e5")
	environment.environment.ambient_light_energy = 0.8
	gallery.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 1.4
	gallery.add_child(light)
	var floor_view := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_view.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("3c6051")
	floor_view.material_override = material
	gallery.add_child(floor_view)
	for tier in 3:
		var chest := BattleChestModel.new()
		chest.tier = tier
		chest.position = Vector3((tier - 1) * 2.65, 0, 0)
		gallery.add_child(chest)
	var camera := Camera3D.new()
	camera.position = Vector3(3.4, 4.1, 8.8)
	camera.fov = 43
	gallery.add_child(camera)
	camera.look_at(Vector3(0, 0.7, 0))
	camera.current = true
