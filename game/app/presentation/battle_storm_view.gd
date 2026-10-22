class_name BattleStormView
extends Node3D
## Cosmetic curtain, terrain rim and local mist share the authoritative circle clock.
const SEGMENTS := 192
const MIST := preload("res://assets/environment/battle_storm/storm_mist.png")
var game: BattleRoyaleGame
var wall: MeshInstance3D
var rim: MeshInstance3D
var edge: ColorRect
var wall_material: ShaderMaterial
var edge_material: ShaderMaterial
var _mesh := ImmediateMesh.new()
var _rim_material: StandardMaterial3D
var _clock: float = 1
var _sample_radius: float = 1

func _ready() -> void:
	wall_material = ShaderMaterial.new()
	wall_material.shader = preload("res://game/app/presentation/battle_storm.gdshader")
	wall_material.set_shader_parameter("mist", MIST)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1
	cylinder.bottom_radius = 1
	cylinder.height = 1
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	cylinder.radial_segments = SEGMENTS
	wall = MeshInstance3D.new()
	wall.mesh = cylinder
	wall.material_override = wall_material
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(wall)
	_rim_material = StandardMaterial3D.new()
	_rim_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rim_material.vertex_color_use_as_albedo = true
	_rim_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rim_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim = MeshInstance3D.new()
	rim.mesh = _mesh
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rim)
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	edge_material = ShaderMaterial.new()
	edge_material.shader = preload("res://game/app/presentation/battle_storm_edge.gdshader")
	edge_material.set_shader_parameter("mist", MIST)
	edge = ColorRect.new()
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.material = edge_material
	layer.add_child(edge)

func present(delta: float) -> void:
	var time := game.match_state.time
	var radius := BattleRing.radius(time)
	var center := BattleRing.center(time, game.match_state.circle)
	var deployed := not game.deployment.active()
	wall.visible = deployed and radius > 0.01
	rim.visible = wall.visible
	wall.position = Vector3(center.x, 80, center.y)
	wall.scale = Vector3(maxf(0.01, radius), 240, maxf(0.01, radius))
	wall_material.set_shader_parameter("phase", time)
	_clock += delta
	if _clock >= 0.25 and radius > 0.01:
		_clock = 0
		_sample_radius = radius
		_build_rim(center, radius)
	rim.position = Vector3(center.x, 0, center.y)
	rim.scale = Vector3.ONE * (maxf(0.01, radius) / _sample_radius)
	rim.scale.y = 1
	var actor := game.bodies[game.watch_slot]
	var distance := Vector2(actor.position.x, actor.position.z).distance_to(center)
	var danger := clampf((distance - radius + 5) / 8, 0, 1)
	edge.visible = deployed and danger > 0 and game.match_state.winner == -2
	edge_material.set_shader_parameter("phase", time)
	edge_material.set_shader_parameter("danger", danger)

func _build_rim(center: Vector2, radius: float) -> void:
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _rim_material)
	var a := _profile(center, Vector2.RIGHT, radius)
	for i in range(1, SEGMENTS + 1):
		var b := _profile(center, Vector2.from_angle(i * TAU / SEGMENTS), radius)
		_quad(a, b, 0, Color("b9fff1ee"))
		_quad(a, b, 1, Color("a95aef85"))
		a = b
	_mesh.surface_end()

func _profile(center: Vector2, direction: Vector2, radius: float) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for distance: float in [maxf(0, radius - 0.65), radius, radius + 3]:
		var at := direction * distance
		var ground := game.world.ground_point(center.x + at.x, center.y + at.y, 0.14)
		points.append(Vector3(at.x, ground.y, at.y))
	return points

func _quad(a: Array[Vector3], b: Array[Vector3], inner: int, tint: Color) -> void:
	for point: Vector3 in [a[inner], b[inner], b[inner + 1], a[inner], b[inner + 1], a[inner + 1]]:
		_mesh.surface_set_color(tint)
		_mesh.surface_add_vertex(point)
