class_name BattleRoyaleGame
extends Node3D
## Separate match composition: authored world, up to 70 actors, one compact stream.

signal leave_requested
signal prepared
signal replay_requested
var room: BattleRoom
var world: Meadow
var bodies: Array[Player] = []
var match_state := BattleMatch.new()
var simulation := BattleAuthority.new()
var replication := BattleReplication.new()
var presentation := BattlePresentation.new()
var recovery := BattleRecovery.new()
var deployment := BattleDeployment.new()
var combat: BattleCombat
var pack: BattlePack
var pack_ui: BattlePackUI
var local_input: LocalPlayerInput
var camera: CameraFollow
var hud: BattleHUD
var local_slot: int = 0
var watch_slot: int = 0
var elapsed: float = 0
var playing: bool = false
var composed: bool = false
var _hud_clock: float = 0
var visibility: BattleVisibility
var match_view := BattleMatchView.new()
var squad: BattleSquadPings
var mobs := BattleMobs.new()
var preferences := GamePreferences.new()
var settings: BattleSettingsFlow

func _ready() -> void:
	set_physics_process(false)
	local_input = LocalPlayerInput.new()
	camera = CameraFollow.new()
	hud = BattleHUD.new()
	replication.game = self
	presentation.game = self
	recovery.game = self
	deployment.game = self
	mobs.game = self
	simulation.mobs = mobs
	room.migration.paused.connect(recovery.pause)
	room.migration.restoring.connect(recovery.restore)
	room.migration.resumed.connect(recovery.resume)
	room.gameplay.connect(replication.receive)
	room.running.connect(_go)
	world = (load("res://game/world/farm/meadow.tscn") as PackedScene).instantiate() as Meadow
	add_child(world)
	for i in room.members.size():
		if room.members[i].key == room.local_key: local_slot = i
	watch_slot = local_slot
	BattleWorldSetup.actors(self)
	combat = BattleCombat.new()
	combat.game = self
	add_child(combat)
	combat.build()
	pack = BattlePack.new()
	pack.game = self
	pack.build()
	simulation.pack = pack
	simulation.combat = combat
	combat.process_mode = Node.PROCESS_MODE_DISABLED
	local_input.name = "BattleLocalInput"
	bodies[local_slot].add_child(local_input)
	camera.target = bodies[local_slot]
	camera.fov = 48
	camera.current = true
	add_child(camera)
	BattleWorldSetup.interiors(self)
	add_child(hud)
	squad = BattleSquadPings.new()
	squad.game = self
	add_child(squad)
	pack_ui = BattlePackUI.new()
	pack_ui.game = self
	add_child(pack_ui)
	var aiming := BattleAimView.new()
	aiming.game = self
	add_child(aiming)
	visibility = BattleVisibility.new()
	visibility.game = self
	add_child(visibility)
	hud.radar.map_bounds = BattleWorldSetup.MAP_BOUNDS
	hud.radar.terrain_map = MapTerrainImage.build(world, BattleWorldSetup.MAP_BOUNDS, 256.0 / 1400)
	hud.leave_requested.connect(leave_requested.emit)
	hud.spectate_requested.connect(next_survivor)
	presentation.build()
	match_view.game = self
	match_view.build()
	settings = BattleSettingsFlow.new()
	settings.game = self
	add_child(settings)
	await get_tree().physics_frame
	if not is_inside_tree(): return
	await get_tree().physics_frame
	if not is_inside_tree(): return
	BattleWorldSetup.place(self)
	deployment.build()
	composed = true
	room.loaded()
	set_physics_process(true)
	_update_hud()
	prepared.emit()

func _go() -> void:
	playing = true
	combat.process_mode = Node.PROCESS_MODE_DISABLED if deployment.active() else Node.PROCESS_MODE_INHERIT

func _physics_process(delta: float) -> void:
	if not composed: return
	if playing:
		elapsed += delta
		deployment.step(delta)
		combat.process_mode = Node.PROCESS_MODE_DISABLED if deployment.active() else Node.PROCESS_MODE_INHERIT
		local_input.enabled = not deployment.active() and not pack_ui.blocked() and not hud.exit_panel.visible and match_state.rows[local_slot][8] > 0 and match_state.rows[local_slot][17] == 0 and match_state.winner == -2
		var command := local_input.sample(bodies[local_slot].position)
		if match_state.rows[local_slot][10] == 0: command.punch_pressed = command.punch_pressed or command.attack_pressed
		if not deployment.active():
			if room.authority(): simulation.step(delta)
			else: _replicas(delta)
		replication.step(delta, command)
	deployment.update()
	pack_ui.update()
	pack.field.update(room.phase != "recovering")
	presentation.update(0 if room.phase == "recovering" else delta)
	_hud_clock += delta
	if _hud_clock >= 0.10:
		_hud_clock = 0
		_update_hud()
	if match_state.rows[watch_slot][8] <= 0 and match_state.alive > 0: next_survivor()

func _replicas(delta: float) -> void:
	mobs.present(delta)
	var age := minf(0.10, elapsed - replication.last_packet)
	for slot in bodies.size():
		var row: Array = match_state.rows[slot]
		var body := bodies[slot]
		body.collision_layer = 2 if row[8] > 0 else 0
		var speed := Vector3(row[3], row[4], row[5])
		var target := match_state.position_of(slot) + speed * age
		body.position = target if body.position.distance_squared_to(target) > 25 else body.position.lerp(target, 1.0 - exp(-22 * delta))
		var command := PlayerCommand.new()
		command.move = Vector2(row[20], row[21])
		command.aim = Vector2(row[6], row[7])
		command.attack_held = presentation.poses[slot] > 0
		body.visuals.present(command, speed, absf(speed.y) < 0.1, row[15] == 1, delta)

func name_of(slot: int) -> String:
	if slot < room.members.size(): return str(room.members[slot].name)
	var skin := slot % 8
	var title: String = "Fufu" if skin == 0 else str(TofufuTestArt.NAMES[skin - 1])
	return tr("CPU %d · %s") % [slot + 1, tr(title)]

func next_survivor() -> void:
	if match_state.rows[local_slot][8] > 0: return
	if BattleOptions.duos(room.options):
		var partner := local_slot ^ 1
		if partner < bodies.size() and match_state.rows[partner][8] > 0:
			watch_slot = partner
			camera.target = bodies[partner]
			camera.reset_follow()
			return
	for offset in range(1, bodies.size() + 1):
		var next := (watch_slot + offset) % bodies.size()
		if match_state.rows[next][8] > 0:
			watch_slot = next
			camera.target = bodies[next]
			camera.reset_follow()
			return

func _update_hud() -> void:
	match_view.update()

func _unhandled_input(event: InputEvent) -> void:
	if not composed or event.is_echo(): return
	if settings.panel.visible: return
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_ESCAPE: hud.exit_panel.visible = not hud.exit_panel.visible
			KEY_N: next_survivor()
			KEY_TAB: hud.toggle_map()
			KEY_G: squad.request(local_input.focus_point)
			KEY_H: squad.request(local_input.focus_point, true)
			_: return
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if pack != null: pack.dispose()
	mobs.game = null
	if room.gameplay.is_connected(replication.receive): room.gameplay.disconnect(replication.receive)
	if room.running.is_connected(_go): room.running.disconnect(_go)
	if room.migration.paused.is_connected(recovery.pause): room.migration.paused.disconnect(recovery.pause)
	if room.migration.restoring.is_connected(recovery.restore): room.migration.restoring.disconnect(recovery.restore)
	if room.migration.resumed.is_connected(recovery.resume): room.migration.resumed.disconnect(recovery.resume)
