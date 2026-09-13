class_name ShootingView
extends Node
## Local camera/input/HUD composition; all firing outcomes stay in combat.

var game: Node3D
var local_input: LocalPlayerInput
var reticle: GunReticle
var shoulder: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	local_input = game.player.command_source as LocalPlayerInput
	reticle = GunReticle.new()
	game.hud.add_child(reticle)

func _process(_delta: float) -> void:
	if not is_instance_valid(local_input): return
	var available: bool = local_input.enabled and not local_input.chat_blocked and game.hud.visible and not get_tree().paused
	var capture: bool = shoulder and available
	var mode := Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode: Input.mouse_mode = mode
	local_input.shoulder_view = shoulder
	game.camera.precise = game.combat.gun.aiming
	reticle.visible = available and game.combat.gun.selected
	reticle.recoil = game.combat.gun.recoil.heat
	reticle.precise = game.combat.gun.aiming
	reticle.centered = shoulder
	reticle.queue_redraw()
	game.hud.show_gun(game.combat.gun.selected, game.combat.gun.aiming)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(local_input): return
	if get_tree().paused or not local_input.enabled or local_input.chat_blocked or not game.hud.visible: return
	if event.is_action_pressed("camera_mode") and not event.is_echo():
		shoulder = not shoulder
		if shoulder:
			var facing: Vector2 = game.combat.equipment.facing
			game.camera.yaw = atan2(-facing.x, -facing.y)
		game.camera.set_shoulder(shoulder)
		game.hud.announce("Behind Fufu / Mouse: orbit · LMB: face + fire · RMB: zoom · C: overhead" if shoulder else "Overhead / Mouse: aim · C: behind Fufu")
		get_viewport().set_input_as_handled()
	elif shoulder and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		game.camera.orbit(event.relative)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
