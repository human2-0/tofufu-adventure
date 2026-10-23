class_name BattleAimView
extends Node
## Adventure camera/input conventions; shot outcomes remain in match combat.
var game: BattleRoyaleGame
var reticle: GunReticle

func _ready() -> void:
	process_priority = -5
	reticle = GunReticle.new()
	game.hud.add_child(reticle)
	_set_behind(true)

func available() -> bool:
	return game.composed and game.playing and game.room.phase != "recovering" and not game.deployment.active() and not game.pack_ui.blocked() and not game.hud.exit_panel.visible and not game.match_view.results.visible and not get_tree().paused

func _process(_delta: float) -> void:
	var active := available()
	var mode := Input.MOUSE_MODE_CAPTURED if active and game.camera.shoulder else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode: Input.mouse_mode = mode
	game.local_input.shoulder_view = game.camera.shoulder
	game.local_input.first_person_view = false
	var combat := game.combat.fighters[game.local_slot].combat
	game.camera.precise = active and (combat.gun.aiming or combat.sotjet.aiming or combat.bow.charge > 0)
	reticle.visible = active and game.local_input.enabled and not game.hud.radar.expanded and combat.ranged_selected()
	reticle.precise = game.camera.precise or combat.bow.selected
	reticle.recoil = combat.gun.recoil.heat
	reticle.centered = game.camera.shoulder
	reticle.reload_remaining = combat.bow.reload_remaining if combat.bow.selected else (combat.gun.reload_remaining if combat.gun.selected else 0.0)
	reticle.reload_progress = SoyGunReloadPose.progress(reticle.reload_remaining)
	reticle.bow_skill = combat.bow.selected
	reticle.skill_charge = combat.bow.charge / AngelBow.CHARGE
	reticle.skill_cooldown = combat.bow.cooldown / AngelBow.COOLDOWN
	reticle.skill_affordable = combat.vitals.current >= AngelBow.COST
	reticle.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not available(): return
	if event.is_action_pressed("camera_mode") and not event.is_echo():
		_set_behind(not game.camera.shoulder)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_direction") and not event.is_echo():
		game.camera.switch_direction()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and game.camera.shoulder and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		game.camera.orbit(event.relative)

func _set_behind(enabled: bool) -> void:
	if enabled:
		var facing := game.local_input.focus_direction()
		game.camera.yaw = atan2(-facing.x, -facing.y)
	game.camera.set_shoulder(enabled)
	game.camera.reset_follow()
	game.local_input.shoulder_view = enabled
	game.local_input.first_person_view = false

func _exit_tree() -> void:
	if is_instance_valid(game.local_input): game.local_input.shoulder_view = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
