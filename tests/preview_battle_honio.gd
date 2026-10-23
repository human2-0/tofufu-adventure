extends SceneTree
## Native atlas/collision-scale gallery and actual Royale warnings, speech and loot.
const OUTPUT := "res://.codex/visualizations/2026/10/23/honio-meniono"
var game: BattleRoyaleGame
var mob: HonioMeniono

func _initialize() -> void:
	_run.call_deferred()

func _shot(name: String) -> void:
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT).path_join(name + ".png"))

func _run() -> void:
	GamePreferences.install_translations(self)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	var gallery := _gallery()
	await _shot("01-forty-authored-poses")
	_skills_gallery(gallery)
	await _shot("01b-generated-skill-effects")
	if OS.get_cmdline_user_args().has("art-only"):
		gallery.free()
		quit()
		return
	gallery.free()
	await process_frame
	var room := BattleRoom.new()
	room.options = [2, 1]
	root.add_child(room)
	room.practice()
	room.epoch = "0".repeat(24)
	game = BattleRoyaleGame.new()
	game.preferences.path = "user://honio-preview-%d.cfg" % Time.get_ticks_usec()
	game.room = room
	root.add_child(game)
	while not game.composed: await physics_frame
	BattleTestDeployment.finish(game)
	game.set_physics_process(false)
	game.combat.process_mode = Node.PROCESS_MODE_DISABLED
	game.local_input.enabled = false
	game.match_state.time = 13
	var at := game.world.ground_point(-22, -22, 0.08)
	game.bodies[0].position = at
	game.bodies[0].visuals.present(PlayerCommand.new(), Vector3.ZERO, true, false, 0)
	for slot in range(1, game.bodies.size()): game.bodies[slot].hide()
	var id := BattleHonioSpawn.site(room.epoch, game.mobs.actors.size())
	mob = game.mobs.actors[id] as HonioMeniono
	for actor in game.mobs.actors:
		if actor != mob: actor.hide()
	mob.position = game.world.ground_point(at.x, at.z - 5, 0.08)
	mob._home = mob.position
	mob.quarry = game.bodies[0]
	game.camera.shoulder = false
	game.camera.first_person = false
	game.camera.reset_follow()
	game.deployment.update()
	game._update_hud()
	mob.melee.begin(HonioMelee.Skill.TOFU_TENDERIZER, Vector3.BACK)
	mob._windup = 1
	for size in [Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = size
		root.content_scale_size = size
		for locale in ["en", "pl"]:
			TranslationServer.set_locale(locale)
			game._update_hud()
			await _shot("02-slam-warning-%d-%s" % [size.x, locale])
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	TranslationServer.set_locale("en")
	mob.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.BACK)
	await _shot("03a-protein-express-warning")
	mob.melee.phase = HonioMelee.Phase.RUSH
	mob.melee.remaining = 0.4
	mob._windup = 0
	await _shot("03-protein-express")
	mob.melee.skill = HonioMelee.Skill.TOFU_TENDERIZER
	mob.melee.recover(1.25)
	mob.melee.impact = 0.25
	await _shot("04-tofu-tenderizer-impact")
	mob.melee.impact = 0
	mob.melee.skill = HonioMelee.Skill.JAB
	mob.melee.impact = 0.25
	await _shot("05-fist-impact")
	mob.target.receive_attack(1000, Vector3.ZERO, Damageable.HitKind.SOY, Vector3.INF, game.combat.fighters[0].health)
	game.pack.field.update(false)
	game._update_hud()
	await _shot("06-finite-bounty")
	game.queue_free()
	room.queue_free()
	await process_frame
	print("Native Honio gallery and Royale encounter: PASS")
	quit()

func _gallery() -> Node3D:
	var gallery := Node3D.new()
	root.add_child(gallery)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("223b40")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 1
	gallery.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.light_energy = 0.8
	gallery.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18
	camera.position = Vector3(0, 22, 30)
	gallery.add_child(camera)
	camera.look_at(Vector3.ZERO)
	for row in 5:
		for column in 8:
			var actor := HonioMeniono.new()
			actor.position = Vector3((column - 3.5) * 3.25, 0, (row - 2) * 4.4)
			gallery.add_child(actor)
			actor.set_physics_process(false)
			actor.target.set_physics_process(false)
			actor.set_process(false)
			actor._warning.hide()
			actor._nameplate.hide()
			actor.speech.hide()
			actor.effects.hide()
			var angle := -column * PI / 4
			var facing := Vector3(sin(angle), 0, cos(angle))
			actor.art.elapsed = 0.1 if row == 2 else 0
			actor.art.present(facing, row in [1, 2], 1 if row > 2 else 0, 2 if row == 4 else 0, 0, 0)
			var label := MobLabels.make(actor, ["S", "SW", "W", "NW", "N", "NE", "E", "SE"][column], 26, 0.015, Color("b6e5d7"), -0.3)
			label.no_depth_test = true
			label.visibility_range_end = 100
	var layer := CanvasLayer.new()
	gallery.add_child(layer)
	var title := Label.new()
	title.position = Vector2(28, 20)
	title.text = "HONIO MENIONO  /  40 AUTHORED POSES\nIdle · run A · run B · punch/rush · overhead slam"
	title.add_theme_font_size_override("font_size", 24)
	layer.add_child(title)
	return gallery

func _skills_gallery(gallery: Node3D) -> void:
	root.size = Vector2i(1600, 600)
	root.content_scale_size = root.size
	for child in gallery.get_children():
		if child is HonioMeniono:
			child.free()
			continue
		if child is CanvasLayer:
			(child.get_child(0) as Label).text = "HONIO MENIONO / GENERATED SKILL VFX\nSlam warning · Protein Express · fist impact · slam dust"
	root.get_camera_3d().size = 9.375
	for index in 4:
		var actor := HonioMeniono.new()
		actor.position = Vector3((index - 1.5) * 6, 0, 0)
		gallery.add_child(actor)
		actor.set_physics_process(false)
		actor.target.set_physics_process(false)
		actor.set_process(false)
		if index == 0:
			actor.melee.begin(HonioMelee.Skill.TOFU_TENDERIZER, Vector3.BACK)
		elif index == 1:
			actor.melee.begin(HonioMelee.Skill.PROTEIN_EXPRESS, Vector3.RIGHT)
			actor.melee.phase = HonioMelee.Phase.RUSH
		else:
			actor.melee.skill = HonioMelee.Skill.JAB if index == 2 else HonioMelee.Skill.TOFU_TENDERIZER
			actor.melee.recover(1.25)
			actor.melee.impact = 0.25
		actor._present_visual(Vector3.ZERO, 0.016)
