class_name ShootingView
extends Node
## Local camera/input/HUD composition; all firing outcomes stay in combat.

var game: Node3D
var local_input: LocalPlayerInput
var reticle: GunReticle
var shoulder: bool = false
var first_person: bool = false
var weapon_view: FirstPersonWeapon
var _local_geometry: Array[GeometryInstance3D] = []
var _layers: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	local_input = game.player.command_source as LocalPlayerInput
	weapon_view = FirstPersonWeapon.new()
	weapon_view.combat = game.combat
	weapon_view.actor = game.player
	game.hud.add_child(weapon_view)
	game.hud.move_child(weapon_view, 0)
	weapon_view.visible = false
	game.combat.gun.visual_muzzle = _gun_muzzle
	game.combat.sotjet.flow.visual.nozzle_provider = _jet_muzzle
	_collect_geometry(game.player.visuals)
	_collect_geometry(game.combat.sword)
	_collect_geometry(game.combat.gun.visual)
	_collect_geometry(game.combat.sotjet.visual)
	_collect_geometry(game.combat._trail)
	reticle = GunReticle.new()
	game.hud.add_child(reticle)

func _process(_delta: float) -> void:
	if not is_instance_valid(local_input): return
	var available: bool = local_input.enabled and not local_input.chat_blocked and game.hud.visible and not get_tree().paused
	var capture: bool = shoulder and available
	var mode := Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode: Input.mouse_mode = mode
	local_input.shoulder_view = shoulder
	local_input.first_person_view = first_person
	weapon_view.visible = first_person and available
	game.camera.precise = game.combat.gun.aiming or game.combat.sotjet.aiming
	reticle.visible = available and (first_person or game.combat.ranged_selected())
	reticle.spread_multiplier = game.progression.progress.shooting_spread_multiplier()
	reticle.recoil = game.combat.gun.recoil.heat
	reticle.precise = game.camera.precise
	reticle.centered = shoulder
	reticle.queue_redraw()
	game.hud.show_gun(game.combat.gun.selected, game.combat.gun.aiming)
	game.hud.show_sotjet(game.combat.sotjet.selected, game.combat.sotjet.milk / game.combat.sotjet.tuning.capacity)
	var first: ItemStack = game.character_equipment.get_slot("combat_1")
	var second: ItemStack = game.character_equipment.get_slot("combat_2")
	game.hud.show_loadout(first.item.name if first != null else "Unarmed", second.item.name if second != null else "Unarmed", game.loadout.active_slot)

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(local_input): return
	if get_tree().paused or not local_input.enabled or local_input.chat_blocked or not game.hud.visible: return
	if event.is_action_pressed("camera_mode") and not event.is_echo():
		cycle_mode()
		get_viewport().set_input_as_handled()
	elif shoulder and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		game.camera.orbit(event.relative)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func cycle_mode() -> void:
	if first_person:
		first_person = false
		shoulder = false
	elif shoulder:
		first_person = true
	else:
		shoulder = true
		var facing: Vector2 = game.combat.equipment.facing
		game.camera.yaw = atan2(-facing.x, -facing.y)
	game.camera.pitch = clampf(game.camera.pitch, -0.4, 1.15)
	game.camera.set_shoulder(shoulder)
	if first_person: game.camera.set_first_person()
	local_input.shoulder_view = shoulder
	local_input.first_person_view = first_person
	for index in _local_geometry.size():
		_local_geometry[index].layers = 0 if first_person else _layers[index]
	var label := "First person / Mouse: look · RMB: aim / guard · C: overhead" if first_person else ("Behind Fufu / Mouse: orbit · C: first person" if shoulder else "Overhead / Mouse: aim · C: behind Fufu")
	game.hud.announce(label)

func _collect_geometry(node: Node) -> void:
	if node is GeometryInstance3D:
		_local_geometry.append(node)
		_layers.append(node.layers)
	for child in node.get_children(): _collect_geometry(child)

func _gun_muzzle() -> Vector3:
	return weapon_view.muzzle_position(game.camera, false) if first_person else game.combat.gun.visual.muzzle_position()

func _jet_muzzle() -> Vector3:
	return weapon_view.muzzle_position(game.camera, true) if first_person else game.combat.sotjet.visual.muzzle_position()
