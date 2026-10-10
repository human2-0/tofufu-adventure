extends SceneTree
## Native Godot contact sheets of every authored celestial frame and held weapon.

const OUT: String = "/Users/mat-dwor/Documents/tofufu-adventure/.codex/visualizations/2026/10/08/celestial/"
const DIRECTIONS: Array[String] = ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
var camera: Camera3D
var stage: Node3D

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1920, 1440)
	stage = Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("354b63")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.9
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -20, 0)
	stage.add_child(sun)
	camera = Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.size = 18.0
	camera.position = Vector3(0, 20, 20)
	camera.look_at(Vector3.ZERO)
	if "--weapons" in OS.get_cmdline_user_args():
		await _weapons()
	else:
		await _art()
	stage.queue_free()
	await process_frame
	print("Celestial native renderer previews saved in ", OUT)
	quit()

func _art() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CelestialFufuArt.DIRECTORY + "sprite-layout.json"))
	for action: String in layout:
		var frames: int = layout[action]["0"].size()
		for first_phase in range(0, frames, 5):
			await _art_page(action, mini(frames - first_phase, 5), first_phase, frames > 5)

func _art_page(action: String, frames: int, first_phase: int, paged: bool) -> void:
	# Native macOS windows clamp tall sheets to the display; keep every phase visible.
	root.size = Vector2i(1920, maxi(420, frames * 215 + 100))
	var group := Node3D.new()
	stage.add_child(group)
	camera.size = 18.0
	for facing in 8:
		for row in frames:
			var phase := first_phase + row
			var body := Node3D.new()
			body.position = camera.global_basis.x * ((facing - 3.5) * 2.1) + camera.global_basis.y * ((frames * 0.5 - row - 0.5) * 2.0)
			group.add_child(body)
			var sprite := FufuVisuals.new()
			sprite.position.y = 0.56
			body.add_child(sprite)
			sprite.worn_set = "celestial"
			sprite.current_facing = facing as FufuVisuals.Facing
			sprite.celestial_art.apply(sprite, facing, action, phase)
			_label(body, "%s / %s / %d" % [action, DIRECTIONS[facing], phase], -0.48)
	await _capture(action + ("-%d" % (first_phase / 5) if paged else ""))
	group.queue_free()
	await process_frame

func _weapons() -> void:
	root.size = Vector2i(1920, 1080)
	var sprites: Array[FufuVisuals] = []
	var combats: Array[PlayerCombat] = []
	camera.size = 18.0
	for kind in 3:
		for facing in 8:
			var body := Node3D.new()
			body.position = camera.global_basis.x * ((facing - 3.5) * 2.1) + camera.global_basis.y * ((1 - kind) * 2.7)
			stage.add_child(body)
			var sprite := FufuVisuals.new()
			sprite.position.y = 0.56
			body.add_child(sprite)
			sprites.append(sprite)
			sprite.worn_set = "celestial"
			sprite.current_facing = facing as FufuVisuals.Facing
			var combat := PlayerCombat.new()
			combat.actor = body
			stage.add_child(combat)
			combat.set_process(false)
			ActorWeaponHands.connect_visuals(sprite, combat)
			CelestialCombat.apply(combat, kind + 1)
			combat.sword.visible = kind == 0
			combat.staff.visible = kind == 1
			combat.gun.visual.visible = kind == 2
			combat.sotjet.visual.hide()
			combats.append(combat)
			_label(body, "%s / %s" % [CelestialCombat.item_id(kind + 1), DIRECTIONS[facing]], -0.8)
	for action in ["idle", "walk", "jump", "windup", "cut", "thrust", "guard", "aim", "reload", "dash", "riding"]:
		for index in sprites.size():
			var sprite := sprites[index]
			var combat := combats[index]
			var aim := Vector2.from_angle((index % 8) * PI / 4.0)
			sprite.celestial_art.apply(sprite, index % 8, action, 3 if action == "jump" else (2 if action in ["walk", "dash"] else 0))
			sprite._present_hand()
			var cutting: bool = action in ["cut", "thrust"]
			var pose := KnifeAttack.pose(KnifeAttack.Style.STAB if action == "thrust" else KnifeAttack.Style.SLASH, combat.actor.global_position, aim, 0.5 if cutting else -1.0, combat.tuning)
			combat.sword.present(pose, aim, 0, cutting, 0 if cutting else 1.0)
			combat.staff.present(pose, 0, false, 0 if cutting else 1.0)
			combat.gun.visual.facing = aim
			combat.gun.visual.reload_remaining = 1.0 if action == "reload" else 0.0
			combat.gun.visual.refresh()
		await _capture("weapons-" + action)

func _label(body: Node3D, text: String, height: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 20
	label.pixel_size = 0.0038
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	body.add_child(label)
	label.position = camera.global_basis.y * height

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")
