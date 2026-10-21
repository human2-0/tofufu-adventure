extends SceneTree
## Render all five authored views and mirrored views at Fufu's world scale.

const DIRECTORY := "res://assets/characters/tofufu/"
const NAMES := ["crispy_tofufu", "smoked_tofufu_green_headband", "panko_tofufu", "golden_tofufu", "smoked_tofufu_steam", "silken_tofufu", "burnt_tofufu"]
const DISPLAY_NAMES := ["Crispy\nTofufu", "Smoked\ngreen headband", "Panko\nTofufu", "Golden\nTofufu", "Smoked\nsteam", "Silken\nTofufu", "Burnt\nTofufu"]
const OUTPUT := "user://tofufu-library-preview"
var gallery := Node3D.new()
var layouts: Array[Dictionary] = []
var sprites: Array[Sprite3D] = []
var direction_labels: Array[Label3D] = []
var fufu_references: Array[FufuVisuals] = []
var caption := Label3D.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1800, 1200)
	root.add_child(gallery)
	var environment := WorldEnvironment.new()
	var background := Environment.new()
	background.background_mode = Environment.BG_COLOR
	background.background_color = Color("283b40")
	environment.environment = background
	gallery.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 11.5
	gallery.add_child(camera)
	camera.position = Vector3(0, 4.3, 20)
	camera.look_at(Vector3(0, 4.3, 0))
	caption.position = Vector3(0, 9.5, 0)
	caption.font_size = 34
	caption.pixel_size = 0.012
	gallery.add_child(caption)
	for index in NAMES.size():
		var folder: String = DIRECTORY + NAMES[index] + "/"
		var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "sprite-layout.json"))
		layouts.append(layout)
		var animations := load(folder + "animations.tres") as SpriteFrames
		assert(animations != null and animations.get_animation_names().size() == 35)
		for row in 5:
			var sprite := Sprite3D.new()
			sprite.shaded = false
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			sprite.alpha_scissor_threshold = 0.5
			gallery.add_child(sprite)
			sprite.position = Vector3((index - 2.5) * 1.75, 7.1 - row * 1.65 + 0.56, 0)
			sprites.append(sprite)
			direction_labels.append(_label(["N", "NW", "W", "SW", "S"][row], sprite.position + Vector3(0, -0.8, 0)))
		_label(DISPLAY_NAMES[index], Vector3((index - 2.5) * 1.75, 8.8, 0))
	for row in 5:
		var fufu := FufuVisuals.new()
		gallery.add_child(fufu)
		fufu.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		fufu.position = Vector3(-6.125, 7.1 - row * 1.65 + 0.56, 0)
		fufu.current_facing = [6, 5, 4, 3, 2][row] as FufuVisuals.Facing
		fufu._set_frame(false)
		fufu_references.append(fufu)
	_label("Fufu\nscale reference", Vector3(-6.125, 8.8, 0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for phase in 5:
		await _show("locomotion", phase, false)
	for phase in 10:
		await _show("jump", phase, false)
	for phase in 4:
		await _show("melee", phase, false)
	await _show("locomotion", 0, true)
	print("PASS: 665 atlas frames; 245 named animations; 20 Godot render boards at ", ProjectSettings.globalize_path(OUTPUT))
	quit()

func _show(kind: String, phase: int, mirrored: bool) -> void:
	caption.text = "%s · frame %d%s" % [kind, phase + 1, " · mirrored right views" if mirrored else ""]
	for row in 5:
		fufu_references[row].current_facing = ([6, 7, 0, 1, 2] if mirrored else [6, 5, 4, 3, 2])[row] as FufuVisuals.Facing
		fufu_references[row]._set_frame(false)
	for index in NAMES.size():
		var sheet: Array = layouts[index].sheets[kind]
		var columns := sheet.size() / 5
		for row in 5:
			var data: Dictionary = sheet[int(row * columns) + phase]
			var sprite := sprites[index * 5 + row]
			direction_labels[index * 5 + row].text = (["N", "NE", "E", "SE", "S"] if mirrored else ["N", "NW", "W", "SW", "S"])[row]
			var region: Array = data.region
			var atlas := AtlasTexture.new()
			atlas.atlas = load(DIRECTORY + NAMES[index] + "/" + kind + ".png") as Texture2D
			atlas.region = Rect2(region[0], region[1], region[2], region[3])
			atlas.filter_clip = true
			sprite.texture = atlas
			sprite.pixel_size = float(data.pixel_size)
			sprite.flip_h = mirrored and row in [1, 2, 3]
			var center := float(region[2]) * 0.5 - float(data.center)
			sprite.offset = Vector2(-center if sprite.flip_h else center, float(data.feet) - float(region[3]) * 0.5 - 0.56 / sprite.pixel_size)
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var path := OUTPUT + "/%s-%02d%s.png" % [kind, phase, "-mirrored" if mirrored else ""]
		assert(root.get_texture().get_image().save_png(path) == OK)

func _label(value: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = 22
	label.pixel_size = 0.012
	label.no_depth_test = true
	gallery.add_child(label)
	return label
