extends SceneTree
## Actual Godot render: applied texture, eight held views, first person and EN/PL UI.

const OUT := "res://.codex/visualizations/2026/10/16/angel-bow/"
var stage: Node3D

func _initialize() -> void: call_deferred("_run")

func capture(label: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1440, 960)
	root.content_scale_size = root.size
	GamePreferences.install_translations(self)
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("263d3c")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.8
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	stage.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9
	stage.add_child(camera)
	camera.position = Vector3(0, 7, 12)
	camera.look_at(Vector3.UP * 0.8)
	var actors := Node3D.new()
	stage.add_child(actors)
	var first_actor: Player
	var first_combat: PlayerCombat
	for index in 8:
		var actor: Player = load("res://game/player/player.tscn").instantiate()
		actors.add_child(actor)
		actor.set_physics_process(false)
		actor.position = Vector3((index % 4 - 1.5) * 2.1, 0, (index / 4) * 3.1 - 1.55)
		var combat := PlayerCombat.new()
		combat.actor = actor
		actors.add_child(combat)
		combat.equipment.knife_selected = false
		combat.sword.hide()
		combat.gun.selected = false
		combat.gun.visual.hide()
		combat.sotjet.visual.hide()
		combat.bow.selected = true
		combat.bow.visual.show()
		ActorWeaponHands.connect_visuals(actor.visuals, combat)
		var command := PlayerCommand.new()
		command.aim = Vector2(sin(index * PI / 4), cos(index * PI / 4))
		combat.bow.visual.facing = command.aim
		actor.visuals.attack_facing = command.aim
		actor.visuals.present(command, Vector3.ZERO, true, false, 0.016)
		if index == 0:
			first_actor = actor
			first_combat = combat
	await capture("eight-directions")
	actors.hide()
	for node in actors.get_children():
		if node is PlayerCombat: node.bow.visual.hide()
	var model := AngelBowModel.new()
	stage.add_child(model)
	model.position.y = 0.9
	camera.size = 2.5
	camera.position = Vector3(2.4, 1.5, 2.6)
	camera.look_at(model.position)
	await capture("textured-model")
	model.hide()
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var view := FirstPersonWeapon.new()
	view.combat = first_combat
	view.actor = first_actor
	layer.add_child(view)
	await capture("first-person-idle")
	first_combat.bow.charge = 1.0
	await capture("first-person-charge")
	first_combat.bow.charge = 0
	first_combat.bow.reload_remaining = 1.0
	await capture("first-person-reload")
	view.hide()
	var hud := HUD.new()
	root.add_child(hud)
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		root.propagate_notification(Node.NOTIFICATION_TRANSLATION_CHANGED)
		HUDCombatView.show_bow_state(hud, true, 0, 0.8, 0, 100)
		await capture("hud-" + locale)
	hud.hide()
	var shop := WeaponShopWindow.new()
	shop.inventory = PlayerInventory.new()
	shop.stock_ids = [AngelBowItem.ID]
	root.add_child(shop)
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		root.propagate_notification(Node.NOTIFICATION_TRANSLATION_CHANGED)
		shop.open()
		shop._first_button.grab_focus()
		shop._tooltip.inspect(shop._first_button, func() -> ItemStack: return ItemStack.new(AngelBowItem.create(), 1))
		await capture("shop-" + locale)
	shop.hide()
	AngelFlameSphere.spawn(stage, Vector3.UP * 0.9)
	camera.size = 9
	camera.position = Vector3(0, 4, 9)
	camera.look_at(Vector3.UP)
	await capture("flame-sphere")
	quit()
