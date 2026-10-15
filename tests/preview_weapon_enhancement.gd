extends SceneTree
## Native rendered close views of enhanced gear, animated spirits, pickup and UI.
const OUT := "res://.codex/visualizations/2026/10/15/magical-tofufu/"
var stage: Node3D
var camera: Camera3D
var bodies: Array[Node3D] = []
var combats: Array[PlayerCombat] = []
var sprites: Array[FufuVisuals] = []

func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	GamePreferences.install_translations(self)
	TranslationServer.set_locale("en")
	root.size = Vector2i(1600, 900)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	stage = Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("29394e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.9
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -20, 0)
	stage.add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.8
	stage.add_child(camera)
	camera.position = Vector3(0, 5, 8)
	camera.look_at(Vector3(0, 0.5, 0))
	for index in 3:
		var body := Node3D.new()
		body.position.x = (index - 1) * 1.8
		stage.add_child(body)
		bodies.append(body)
		var sprite := FufuVisuals.new()
		sprite.position.y = 0.56
		body.add_child(sprite)
		sprites.append(sprite)
		var combat := PlayerCombat.new()
		combat.actor = body
		stage.add_child(combat)
		combat.set_process(false)
		ActorWeaponHands.connect_visuals(sprite, combat)
		combat.equipment.knife_selected = index == 0
		combat.equipment.staff_owned = index == 1
		combat.equipment.staff_selected = index == 1
		combat.gun.selected = index == 2
		combat.sword.visible = index == 0
		combat.staff.visible = index == 1
		combat.gun.visual.visible = index == 2
		combat.sotjet.visual.hide()
		combat.equipment.weapon_enhanced = true
		combats.append(combat)
		var view := ActorEnhancedWeaponView.new()
		view.combat = combat
		stage.add_child(view)
		_label(body, ["Enhanced Knife", "Enhanced Staff", "Enhanced Soybean Gun"][index], Vector3(0, -0.45, 0))
		var command := PlayerCommand.new()
		command.aim = Vector2.RIGHT
		sprite.present(command, Vector3.ZERO, true, false, 0.016, 0, 0)
		var pose := SwordGeometry.pose(body.position, Vector2.RIGHT, -1.0, combat.tuning)
		combat.sword.present(pose, Vector2.RIGHT, 0)
		combat.staff.present(pose)
		combat.gun.visual.facing = Vector2.RIGHT
		combat.gun.visual.refresh()
	await _capture("held-phase-1")
	await create_timer(0.65).timeout
	await _capture("held-phase-2")
	var drop := WorldItemDrop.new()
	drop.item_id = MagicalTofufu.ID
	drop.authoritative = false
	stage.add_child(drop)
	drop.position = Vector3(0, 0.3, 2)
	WorldItemVisuals.build(drop)
	_label(drop, "Magical Tofufu Chunk · 0.1% mob drop", Vector3(0, -0.35, 0))
	await _capture("chunk-and-weapons")
	for index in 3: CelestialCombat.apply(combats[index], index + 1)
	await _capture("celestial-weapons")
	for combat in combats: CelestialCombat.apply(combat, 0)
	combats[2].gun.selected = false
	combats[2].gun.visual.hide()
	combats[2].sotjet.selected = true
	combats[2].sotjet.visual.show()
	await _capture("soyjet")
	combats[2].sotjet.selected = false
	combats[2].sotjet.visual.hide()
	combats[2].gun.selected = true
	combats[2].gun.visual.show()
	var overlay := FirstPersonWeapon.new()
	overlay.combat = combats[2]
	overlay.actor = CharacterBody3D.new()
	stage.add_child(overlay.actor)
	root.add_child(overlay)
	await _capture("first-person-gun")
	overlay.queue_free()
	var window := InventoryWindow.new()
	window.inventory = PlayerInventory.new()
	window.equipment = CharacterEquipment.new()
	window.equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack("factory_backpack")))
	window.inventory.set_slot(0, ItemStack.new(MagicalTofufu.create(), 2))
	var weapon := ItemStack.new(InventoryItem.weapon("soy_gun"))
	weapon.enhanced = true
	window.equipment.set_slot("combat_2", weapon)
	root.add_child(window)
	window.open()
	await process_frame
	window._eq_buttons["combat_2"].grab_focus()
	window._tooltip.inspect(window._eq_buttons["combat_2"], func() -> ItemStack: return weapon)
	await _capture("inventory-enhanced")
	window._inv_buttons[0].grab_focus()
	window._tooltip.inspect(window._inv_buttons[0], func() -> ItemStack: return window.inventory.get_slot(0))
	await _capture("inventory-chunk")
	window._tooltip.clear()
	weapon.enhanced = false
	window.refresh()
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		window.execute_transfer("inventory", 0, "equipment", "combat_2")
		await _capture("confirmation-gun-" + locale)
		window.enhancement_confirmation.clear()
	window.inventory.set_slot(1, ItemStack.new(InventoryItem.weapon("sotjet")))
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		window.execute_transfer("inventory", 0, "inventory", 1)
		await _capture("confirmation-soyjet-" + locale)
		window.enhancement_confirmation.clear()
	window.close()
	root.size = Vector2i(640, 360)
	window.open()
	TranslationServer.set_locale("pl")
	window.execute_transfer("inventory", 0, "inventory", 1)
	await _capture("confirmation-soyjet-pl-compact")
	window.enhancement_confirmation.clear()
	print("Magical Tofufu native previews: ", ProjectSettings.globalize_path(OUT))
	quit()

func _label(parent: Node3D, text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 26
	label.pixel_size = 0.0035
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = at
	parent.add_child(label)

func _capture(file: String) -> void:
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + file + ".png")
