extends SceneTree
## Native reference/current capsule comparison; no launcher, preference or save access.
const OUTPUT := ".codex/visualizations/2026/10/23/firm-movement"
const DT := 1.0 / 60.0
class MotionInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.aim = move if not move.is_zero_approx() else Vector2.DOWN
		return command

class PreviousMotor extends PlayerMotor:
	func step(command: PlayerCommand, velocity: Vector3, grounded: bool, delta: float) -> Vector3:
		var result := super.step(command, velocity, grounded, delta)
		var planar := Vector2(velocity.x, velocity.z)
		var move := command.move.limit_length()
		var rate := _tuning.acceleration if move.length_squared() > 0.01 else _tuning.friction
		if move.length_squared() > 0.01 and planar.dot(move) < -0.1: rate = _tuning.turn_braking
		rate *= surface_grip if grounded else _tuning.air_control
		planar = planar.move_toward(move * _tuning.walk_speed, rate * delta)
		result.x = planar.x
		result.z = planar.y
		return result

var actors: Array[Player] = []
var inputs: Array[MotionInput] = []
var paths: Array = [[], []]
var title: Label
var readout: Label
var output: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	root.theme = MenuStyle.make_theme()
	var world := Node3D.new()
	root.add_child(world)
	_fixture(world)
	for i in 2:
		var actor: Player = load("res://game/player/player.tscn").instantiate()
		var source := MotionInput.new()
		actor.add_child(source)
		actor.command_source = source
		actor.position = Vector3(-3, 0.05, (i - 0.5) * 3.0)
		world.add_child(actor)
		actor.set_physics_process(false)
		actor.visuals.set_test_skin("smoked_tofufu_green_headband")
		if i == 0: actor.motor = PreviousMotor.new(actor.tuning)
		actors.append(actor)
		inputs.append(source)
		var label := Label3D.new()
		label.text = "Previous response" if i == 0 else "Firm steering + curved stop"
		label.position = Vector3(-3, 0.05, actor.position.z - 0.65)
		label.rotation.x = -PI * 0.5
		label.font_size = 30
		label.pixel_size = 0.008
		world.add_child(label)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 9, 6)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.5
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var ui := CanvasLayer.new()
	root.add_child(ui)
	title = MenuStyle.label(ui, "Firm footing · real movement comparison", 24, MenuStyle.CREAM)
	title.position = Vector2(24, 20)
	readout = MenuStyle.label(ui, "", 19, MenuStyle.SOY_GOLD)
	readout.position = Vector2(24, 58)
	for tick in 30: await _tick()
	for source in inputs: source.move = Vector2.RIGHT
	for tick in 45: await _tick()
	await _shot("01-walking")
	for source in inputs: source.move = Vector2.DOWN
	for tick in 5: await _tick()
	await _shot("02-turn-five-ticks")
	for tick in 25: await _tick()
	for source in inputs: source.move = Vector2.ZERO
	var released: Array[Vector3] = [actors[0].position, actors[1].position]
	var stopped := [-1.0, -1.0]
	for tick in 30:
		await _tick()
		for i in 2:
			if stopped[i] < 0 and Vector2(actors[i].velocity.x, actors[i].velocity.z).length() < 0.001: stopped[i] = (tick + 1) * DT
		if tick == 2: await _shot("03-release-50ms")
		if tick == 9: await _shot("04-release-167ms")
	_trails(world)
	await _shot("05-stopped")
	var report := {"stop_seconds": stopped, "stop_distances_m": [actors[0].position.distance_to(released[0]), actors[1].position.distance_to(released[1])], "scope": "Actual grounded CharacterBody3D motion: previous linear reference and shared current motor. Firm Tofufu art, 60 Hz, collision-backed floor; no preference/save writes."}
	FileAccess.open(output.path_join("measurements.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print(JSON.stringify(report))
	quit(0 if stopped[1] > 0 and stopped[1] < stopped[0] else 1)

func _tick() -> void:
	for i in 2:
		actors[i]._physics_process(DT)
		paths[i].append(actors[i].position)
	await physics_frame

func _shot(name: String) -> void:
	readout.text = "Previous %.2f m/s       Current %.2f m/s" % [Vector2(actors[0].velocity.x, actors[0].velocity.z).length(), Vector2(actors[1].velocity.x, actors[1].velocity.z).length()]
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))

func _trails(world: Node3D) -> void:
	for i in 2:
		var mesh := ImmediateMesh.new()
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("f4c75d") if i == 0 else Color("a4ebbd")
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
		for at: Vector3 in paths[i]: mesh.surface_add_vertex(at + Vector3.UP * 0.03)
		mesh.surface_end()
		var view := MeshInstance3D.new()
		view.mesh = mesh
		world.add_child(view)

func _fixture(world: Node3D) -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 1, 30)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	world.add_child(floor_body)
	var floor_view := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_view.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("31514c")
	floor_view.material_override = material
	world.add_child(floor_view)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -25, 0)
	world.add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
