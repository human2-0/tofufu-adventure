class_name ShootingView
extends Node
## Local camera/input/HUD composition; all firing outcomes stay in combat.

var game: Node3D
var local_input: LocalPlayerInput
var reticle: GunReticle
var shoulder: bool = false
var first_person: bool = false
var weapon_view: FirstPersonWeapon
var run_pose := GunRunPose.new()
var _local_geometry: Array[GeometryInstance3D] = []
var _layers: Array[int] = []
var _inventory_inspection: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -5 # After replica presentation, before weapon visuals.
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
	_collect_geometry(game.combat.staff)
	_collect_geometry(game.combat.gun.visual)
	_collect_geometry(game.combat.sotjet.visual)
	_collect_geometry(game.combat._trail)
	game.combat.sword.model_changed.connect(_refresh_weapon_geometry)
	game.combat.staff.model_changed.connect(_refresh_weapon_geometry)
	reticle = GunReticle.new()
	game.hud.add_child(reticle)

func _process(delta: float) -> void:
	if not is_instance_valid(local_input): return
	var available: bool = local_input.enabled and not local_input.chat_blocked and game.hud.visible and not get_tree().paused
	var capture: bool = shoulder and available
	var mode := Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
	if Input.mouse_mode != mode: Input.mouse_mode = mode
	local_input.shoulder_view = shoulder
	local_input.first_person_view = first_person
	_update_run_pose(delta, available)
	weapon_view.visible = first_person and available
	game.camera.precise = game.combat.gun.aiming or game.combat.sotjet.aiming
	reticle.visible = available and (first_person or game.combat.ranged_selected())
	reticle.spread_multiplier = game.progression.progress.shooting_spread_multiplier()
	reticle.recoil = game.combat.gun.recoil.heat
	reticle.precise = game.camera.precise
	reticle.centered = shoulder
	reticle.reload_remaining = game.combat.gun.reload_remaining if game.combat.gun.selected else 0.0
	reticle.reload_progress = SoyGunReloadPose.progress(reticle.reload_remaining)
	reticle.queue_redraw()
	game.hud.show_gun(game.combat.gun.selected, game.combat.gun.aiming)
	game.hud.show_gun_status(game.combat.gun.magazine, game.combat.gun.reload_remaining, game.combat.gun.charge_elapsed, game.combat.gun.selected)
	game.hud.show_sotjet(game.combat.sotjet.selected, game.combat.sotjet.milk / game.combat.sotjet.tuning.capacity)
	var first: ItemStack = game.character_equipment.get_slot("combat_1")
	var second: ItemStack = game.character_equipment.get_slot("combat_2")
	game.hud.show_loadout(_item_label(first), _item_label(second), game.loadout.active_slot)
	game.hud.show_staff_state(game.combat.equipment.staff_selected, game.combat.active and game.combat.attack_style == StaffAttack.TORNADO, game.combat.rules.cooldown)
	game.hud.show_nori_state(game.combat.equipment.nori_selected, game.combat.plunge.active, game.combat.plunge.cooldown)
	game.hud.show_pod_state(game.combat.equipment.pod_selected, game.combat.podburst.cooldown)

func _update_run_pose(delta: float, available: bool) -> void:
	var in_view: bool = shoulder and game.camera.shoulder and game.combat.ranged_selected() and not game.player.transport_active
	if not in_view:
		run_pose.reset()
	elif not get_tree().paused:
		var motor: PlayerMotor = game.player.motor
		var moving: bool = Vector2(game.player.velocity.x, game.player.velocity.z).length_squared() > 0.04
		# Guest snapshots restore the reserve between predicted movement ticks.
		var run_requested: bool = Input.is_action_pressed("run") and not Input.get_vector("move_left", "move_right", "move_up", "move_down").is_zero_approx()
		var running: bool = motor.endurance.running or (run_requested and not motor.endurance.exhausted and motor.endurance.current > 0.0)
		var engaged: bool = Input.is_action_pressed("attack") or Input.is_action_pressed("guard") or game.combat.gun.aiming or game.combat.sotjet.aiming or game.combat.sotjet.firing
		var reloading: bool = game.combat.gun.selected and game.combat.gun.reload_remaining > 0.0
		run_pose.step(available and moving and running and not motor.is_dashing and not motor.is_charging_dash and not engaged and not reloading, delta)
	local_input.camera_aim_offset = run_pose.aim_offset()
	reticle.aim_offset = run_pose.aim_offset()
	weapon_view.run_lowering = run_pose.blend
	game.combat.gun.visual.run_lowering = run_pose.blend
	game.combat.sotjet.visual.run_lowering = run_pose.blend

func _item_label(stack: ItemStack) -> String:
	if stack == null or stack.item == null: return "Unarmed"
	if stack.item.weapon_level > 0:
		return "%s L%d P%d" % ["Staff" if stack.item.id == "sproutwood_staff" else stack.item.name, stack.item.weapon_level, stack.item.weapon_power]
	return stack.item.name

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(local_input): return
	if get_tree().paused or not local_input.enabled or local_input.chat_blocked or not game.hud.visible: return
	if event.is_action_pressed("camera_mode") and not event.is_echo():
		cycle_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("camera_direction") and not event.is_echo():
		if _inventory_inspection: return
		var label: String = game.camera.switch_direction()
		if not label.is_empty(): game.hud.announce(label + " · MMB: switch view")
		get_viewport().set_input_as_handled()
	elif shoulder and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		game.camera.orbit(event.relative)

func _exit_tree() -> void:
	if is_instance_valid(local_input): local_input.camera_aim_offset = Vector2.ZERO
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
	if not shoulder: _update_run_pose(0.0, false)
	for index in _local_geometry.size():
		_local_geometry[index].layers = 0 if first_person else _layers[index]
	var label := "First person / Mouse: look · RMB: aim / guard · C: overhead" if first_person else ("Behind Fufu / Mouse: orbit · MMB: switch shoulder · C: first person" if shoulder else "Overhead / Mouse: aim · MMB: rotate · C: behind Fufu")
	game.hud.announce(label)

func set_inventory_inspection(active: bool) -> void:
	_inventory_inspection = active
	# Inspect the real actor even when the player opened the bag from first person.
	if active:
		game.camera.set_shoulder(false)
		_update_run_pose(0.0, false)
	else:
		game.camera.set_shoulder(shoulder)
		if first_person: game.camera.set_first_person()
	for index in _local_geometry.size():
		_local_geometry[index].layers = 0 if first_person and not active else _layers[index]

func _collect_geometry(node: Node) -> void:
	if node is GeometryInstance3D and node not in _local_geometry:
		_local_geometry.append(node)
		_layers.append(node.layers)
		if first_person and not _inventory_inspection: node.layers = 0
	for child in node.get_children(): _collect_geometry(child)

func _refresh_weapon_geometry() -> void:
	# Replacing a blade frees its meshes; retain live hand/debug layers and add art.
	for index in range(_local_geometry.size() - 1, -1, -1):
		if not is_instance_valid(_local_geometry[index]):
			_local_geometry.remove_at(index)
			_layers.remove_at(index)
	_collect_geometry(game.combat.sword)
	_collect_geometry(game.combat.staff)

func _gun_muzzle() -> Vector3:
	return weapon_view.muzzle_position(game.camera, false) if first_person else game.combat.gun.visual.muzzle_position()

func _jet_muzzle() -> Vector3:
	return weapon_view.muzzle_position(game.camera, true) if first_person else game.combat.sotjet.visual.muzzle_position()
