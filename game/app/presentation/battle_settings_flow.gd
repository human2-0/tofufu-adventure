class_name BattleSettingsFlow
extends Node
## Device-local graphics shared with the launcher; no match pause or peer mutation.

var game: BattleRoyaleGame
var panel: BattleGraphicsPanel
var scenery: BattleSceneryView

func _ready() -> void:
	scenery = BattleSceneryView.new()
	scenery.world = game.world
	scenery.preferences = game.preferences.graphics
	add_child(scenery)
	panel = BattleGraphicsPanel.new()
	add_child(panel)
	panel.closed.connect(panel.hide)
	panel.rendering_requested.connect(_render)
	panel.scenery_requested.connect(func(distance: int, shadows: bool) -> void:
		game.preferences.graphics.set_scenery(distance, shadows)
		_save())
	panel.effect_requested.connect(func(key: String, enabled: bool) -> void:
		game.preferences.graphics.set_enabled(key, enabled)
		_save())
	panel.performance_requested.connect(_performance)
	game.hud.graphics_requested.connect(open)
	game.room.migration.paused.connect(_recovering)

func open() -> void:
	game.pack_ui.close()
	game.hud.exit_panel.show()
	var preferences := game.preferences
	var effects := {}
	for key in panel.effects: effects[key] = preferences.graphics.enabled(key)
	panel.display({"limit": preferences.frame_limit, "scale": preferences.render_scale, "sync": preferences.vsync,
		"adaptive": preferences.adaptive_resolution, "distance": preferences.graphics.scenery_distance,
		"shadows": preferences.graphics.shadows, "effects": effects})

func _render(limit: int, scale: float, sync: bool, adaptive: bool) -> void:
	game.preferences.adaptive_resolution = adaptive
	game.preferences.apply_rendering(game.get_viewport(), limit, scale, sync)
	_save()

func _performance() -> void:
	game.preferences.graphics.use_performance_preset()
	_render(60, 0.65, false, false)
	open()

func _save() -> void:
	panel.message.text = "Graphics saved." if game.preferences.save() == OK else "Could not save preferences."

func _recovering() -> void:
	panel.hide()

func _exit_tree() -> void:
	if game.room.migration.paused.is_connected(_recovering): game.room.migration.paused.disconnect(_recovering)
