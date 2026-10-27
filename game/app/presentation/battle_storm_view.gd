class_name BattleStormView
extends Node3D
## Cosmetic curtain, terrain rim and local mist share the authoritative circle clock.
const SEGMENTS := BattleStormRim.SEGMENTS
const MIST := preload("res://assets/environment/battle_storm/storm_mist.png")
var game: BattleRoyaleGame
var wall: MeshInstance3D
var rim: MeshInstance3D
var edge: ColorRect
var wall_material: ShaderMaterial
var edge_material: ShaderMaterial
var _terrain_rim := BattleStormRim.new()
var _rim_material: StandardMaterial3D
var _clock: float = 1

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
	_terrain_rim.ground_point = game.world.ground_point
	_terrain_rim.material = _rim_material
	rim.mesh = _terrain_rim.mesh
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
	wall.position = Vector3(center.x, 80, center.y)
	wall.scale = Vector3(maxf(0.01, radius), 240, maxf(0.01, radius))
	wall_material.set_shader_parameter("phase", time)
	_clock += delta
	if deployed and radius > 0.01 and delta > 0:
		if _clock >= 0.25 and _terrain_rim.request(center, radius): _clock = 0
		_terrain_rim.step()
	rim.visible = wall.visible and _terrain_rim.mesh.get_surface_count() > 0
	rim.position = Vector3(center.x, 0, center.y)
	rim.scale = Vector3.ONE * (maxf(0.01, radius) / _terrain_rim.radius)
	rim.scale.y = 1
	var actor := game.bodies[game.watch_slot]
	var distance := Vector2(actor.position.x, actor.position.z).distance_to(center)
	var danger := clampf((distance - radius + 5) / 8, 0, 1)
	edge.visible = deployed and danger > 0 and game.match_state.winner == -2
	edge_material.set_shader_parameter("phase", time)
	edge_material.set_shader_parameter("danger", danger)
