class_name BattleSettingsFlow
extends Node
## Device-local graphics shared with the launcher; no match pause or peer mutation.

var game: BattleRoyaleGame
var panel: BattleGraphicsPanel
var scenery: BattleSceneryView
var _confirm: ConfirmationDialog
var _remaining: float = 0.0
var _old_resolution: int
var _old_fullscreen: bool

func _ready() -> void:
	scenery = BattleSceneryView.new()
	scenery.world = game.world
	scenery.preferences = game.preferences.graphics
	add_child(scenery)
	panel = BattleGraphicsPanel.new()
	panel.resolutions = GamePreferences.RESOLUTIONS
	add_child(panel)
	panel.closed.connect(panel.hide)
	panel.rendering_requested.connect(_render)
	panel.display_requested.connect(_preview_display)
	panel.visibility_changed.connect(func() -> void:
		if not panel.visible: _revert_display())
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
		"shadows": preferences.graphics.shadows, "effects": effects,
		"resolution": preferences.resolution, "fullscreen": preferences.fullscreen})

func _preview_display(index: int, fullscreen: bool) -> void:
	if _remaining > 0: return
	_old_resolution = game.preferences.resolution
	_old_fullscreen = game.preferences.fullscreen
	game.preferences.apply_display(index, fullscreen)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Keep this display setting?"
	_confirm.ok_button_text = "Keep"
	_confirm.cancel_button_text = "Revert"
	_confirm.dialog_hide_on_ok = false
	_confirm.exclusive = true
	add_child(_confirm)
	_remaining = 15.0
	_confirm.dialog_text = "Reverting automatically in %d seconds." % 15
	_confirm.confirmed.connect(_keep_display)
	_confirm.canceled.connect(_revert_display)
	_confirm.popup_centered(Vector2i(430, 150))

func _keep_display() -> void:
	_remaining = 0
	_confirm.queue_free()
	_save()
	open()

func _process(delta: float) -> void:
	if _remaining <= 0: return
	_remaining -= delta
	_confirm.dialog_text = "Reverting automatically in %d seconds." % ceili(_remaining)
	if _remaining <= 0: _revert_display()

func _revert_display() -> void:
	if not is_instance_valid(_confirm) or _confirm.is_queued_for_deletion(): return
	_remaining = 0
	game.preferences.apply_display(_old_resolution, _old_fullscreen)
	_confirm.queue_free()
	panel.window_size.select(game.preferences.resolution)
	panel.fullscreen.set_pressed_no_signal(game.preferences.fullscreen)

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
	_revert_display()
	if game.room.migration.paused.is_connected(_recovering): game.room.migration.paused.disconnect(_recovering)
