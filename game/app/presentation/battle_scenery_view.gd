class_name BattleSceneryView
extends Node
## Rendering-server distance culling leaves world collision and match simulation intact.

var world: Meadow
var preferences: GraphicsPreferences
var geometry: Array[GeometryInstance3D] = []
var lights: Array[Light3D] = []
var _ranges: Array[float] = []
var _radii: Array[float] = []
var _shadows: Array[bool] = []
var _fog: Environment
var _fog_mode: Environment.FogMode
var _fog_defaults: Array[float] = []

func _ready() -> void:
	process_priority = 1 # After the local day/night cycle updates its fog colour/density.
	_fog = (world.get_node("EnvironmentCycle") as EnvironmentCycle).world_environment.environment
	_fog_mode = _fog.fog_mode
	_fog_defaults = [_fog.fog_depth_begin, _fog.fog_depth_end, _fog.fog_depth_curve, _fog.fog_density]
	_collect(world)
	preferences.changed.connect(apply)
	apply()

func _collect(parent: Node) -> void:
	for child in parent.get_children():
		if child is GeometryInstance3D:
			var view := child as GeometryInstance3D
			geometry.append(view)
			_ranges.append(view.visibility_range_end)
			# Range checks use the AABB centre. Include its radius so near cover never vanishes.
			var bounds := view.global_transform * view.get_aabb()
			_radii.append(bounds.size.length() * 0.5 + view.extra_cull_margin)
		if child is Light3D:
			lights.append(child)
			_shadows.append(child.shadow_enabled)
		_collect(child)

func apply() -> void:
	for index in geometry.size():
		var view := geometry[index]
		var distance := float(preferences.scenery_distance)
		var limit := distance + _radii[index] if distance > 0 else 0.0
		if _ranges[index] > 0: limit = minf(limit, _ranges[index]) if limit > 0 else _ranges[index]
		view.visibility_range_end = limit
		# Hysteresis avoids boundary flicker without adding transparent draw passes.
		if _ranges[index] == 0: view.visibility_range_end_margin = 12.0 if limit > 0 else 0.0
	for index in lights.size(): lights[index].shadow_enabled = _shadows[index] and preferences.shadows
	var cycle := world.get_node("EnvironmentCycle") as EnvironmentCycle
	cycle.fog_enabled = preferences.enabled("fog")
	cycle.motes_enabled = preferences.enabled("motes")
	cycle.sky_effects.lightning_enabled = preferences.enabled("lightning")
	cycle.sky_effects.thunder_enabled = preferences.enabled("thunder")
	_haze()
	world.grass_material.set_shader_parameter("wind_animation", 1.0 if preferences.enabled("wind") else 0.0)
	world.rain_effects.set_effects_enabled(preferences.enabled("puddles"))

func _haze() -> void:
	var distance := float(preferences.scenery_distance)
	_fog.fog_mode = Environment.FOG_MODE_DEPTH if distance > 0 else _fog_mode
	if distance > 0:
		_fog.fog_depth_begin = maxf(110, distance * 0.65)
		_fog.fog_depth_end = distance - 16
		_fog.fog_depth_curve = 2.0
	else:
		_fog.fog_depth_begin = _fog_defaults[0]
		_fog.fog_depth_end = _fog_defaults[1]
		_fog.fog_depth_curve = _fog_defaults[2]
		_fog.fog_density = _fog_defaults[3]
	set_process(distance > 0 and preferences.enabled("fog"))
	if is_processing(): _process(0)

func _process(_delta: float) -> void:
	# Depth fog uses density as maximum opacity. Keep the cutoff hidden after cycle updates.
	_fog.fog_density = 1.0

func _exit_tree() -> void:
	if preferences.changed.is_connected(apply): preferences.changed.disconnect(apply)
