class_name CastleAdventure
extends Node3D
## Castle lifecycle composes puzzle rules, interaction, combat, persistence and views.

var game: AdventureGame
var castle: LavaCastle
var state := CastleTrialState.new()
var party := CastleParty.new()
var encounter := CastleEncounter.new()
var view := CastleTrialView.new()
var treasure := CastleTreasure.new()
var authoritative: bool = true
var replica_initialized: bool = false
var notice_time: float = 0.0
var _last_message: String = ""
var _view_revision: int = -1
var _connected: Array[Player] = []
var _command_cooldown: Dictionary = {}

func _ready() -> void:
	name = "CastleAdventure"
	castle = game.world.volcanic.castle
	party.flow = self
	treasure.flow = self
	encounter.flow = self
	encounter.build()
	game.add_child(view)
	_connect_actor(game.player)
	present_state()

func configure_party(members: Dictionary, authority: bool) -> void:
	authoritative = authority
	party.members = members
	party.adopt_solo()
	if game.player.command_sampled.is_connected(_command.bind(game.player)):
		game.player.command_sampled.disconnect(_command.bind(game.player))
	_connected.clear()
	sync_party()
	encounter.authority(authority)

func sync_party() -> void:
	for member: CoopActor in party.members.values():
		if authoritative: _connect_actor(member.actor)

func _connect_actor(actor: Player) -> void:
	if actor in _connected: return
	_connected.append(actor)
	actor.command_sampled.connect(_command.bind(actor))

func _command(command: PlayerCommand, _delta: float, actor: Player) -> void:
	if not authoritative or command.cancel_actions or not command.pickup_pressed: return
	var action := command.castle_action
	if action < 0 or action > 24 or command.castle_revision != state.revision: return
	if actor not in party.actors() or not reachable(actor, action): return
	var id := actor.get_instance_id()
	var now := Time.get_ticks_msec()
	if now - int(_command_cooldown.get(id, -1000)) < 180: return
	_command_cooldown[id] = now
	if action < 12: state.operate(action)
	elif action == 12: _king_interaction(actor)
	else: treasure.claim(actor, action - 13)
	present_state()

func _king_interaction(actor: Player) -> void:
	if encounter.king.active: return
	if state.completed:
		party.claim(actor)
	elif not state.all_open(): state.message = "KING LAVA: Restore all three wards and face their guardians before our trial."
	elif not state.introduced:
		state.introduced = true
		state.revision += 1
		state.message = "KING LAVA: For centuries I kept this sea from boiling. Anger outlived memory. You restored my wards; now face the fire I could not put to rest. Speak again when ready."
	else: encounter.begin()

func focus_position(action: int) -> Vector3:
	if action >= 13 and action <= 24: return treasure.chest(action - 13).global_position + Vector3.UP * 0.75
	if action == 12: return encounter.king.global_position + Vector3.UP
	if action < 0 or action >= 12: return Vector3.INF
	return castle.floors[action / 4].trial.controls[action % 4].global_position + Vector3.UP * 1.2

func reachable(actor: Player, action: int) -> bool:
	if action < 0 or action > 24: return false
	if action >= 13 and state.treasure_claimed(party.key(actor), action - 13): return false
	if action == 12 and encounter.king.active: return false
	var at := focus_position(action)
	if actor.global_position.distance_to(at - Vector3.UP) > (5.5 if action == 12 else 3.2): return false
	if action < 12 and absf(castle.floors[action / 4].to_local(actor.global_position).y) > 2: return false
	if action >= 13 and absf(castle.floors[(action - 13) / 4].to_local(actor.global_position).y) > 2: return false
	if action == 12 and not party.inside_arena(actor): return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, at, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or (action >= 13 and hit.collider.get_parent() == treasure.chest(action - 13))

func prompt(action: int) -> String:
	if action >= 13: return "Search hidden chest · Golden Tofu ×3"
	if action < 12: return "Operate " + str(CastleTrialGeometry.LABELS[action / 4][action % 4])
	if state.completed: return "Receive King Lava's blessing" if party.key(game.player) not in state.rewarded else "The fire remembers your courage"
	return "Speak to King Lava" if not state.introduced else "Challenge King Lava"

func _physics_process(delta: float) -> void:
	if not authoritative: return
	party.step(delta)
	encounter.step(delta)

func _process(_delta: float) -> void:
	notice_time = maxf(0, notice_time - _delta)
	party.present_burns()
	var king := encounter.king
	castle.king.global_position = king.global_position if authoritative or castle.king.global_position.distance_to(king.global_position) > 3 else castle.king.global_position.lerp(king.global_position, minf(1, _delta * 16))
	castle.king.sprite.facing = king.facing
	castle.king.sprite.set_pose(king.pose)
	castle.king.greeting_enabled = not king.active
	castle.king.greeting.text = "Even fire must learn patience.\nSpeak to me when you are ready." if not state.completed else "You taught the flame to remember.\nAccept my blessing, young Fufu."
	if king.active: castle.king.greeting.visible = false
	if _view_revision != state.revision: present_state()
	var shown := game.hud.visible and castle.contains(game.player.global_position) and not game.player.transport_active
	var action := ""
	if game.world_items.focused_kind == "castle" and (not king.active or game.world_items.focused_plot >= 13): action = "[%s] %s" % [GamePreferences.binding_text("pickup_weapon", "keyboard"), prompt(game.world_items.focused_plot)]
	var local := castle.to_local(game.player.global_position)
	var deck := clampi(floori(local.y / 8), 0, 3)
	var heading: String = "KING LAVA · PHASE %d" % king.phase if king.active else "TOFUFU CASTLE · " + (["RESTRAINT", "MEMORY", "MEASURE", "ROYAL PLAZA"][deck])
	var text := CastleHudCopy.text(self, deck, not action.is_empty())
	view.present(shown, heading, text, action, king.target.current, king.target.maximum if king.active else 0)

func present_state() -> void:
	if state.message != _last_message and _view_revision >= 0: notice_time = 6
	_last_message = state.message
	treasure.present(_view_revision >= 0)
	_view_revision = state.revision
	for deck in 3:
		castle.floors[deck].trial.present_state(state.solved[deck], state.gate_open(deck), state.lever_bits, state.sequence_step, state.dials, state.feedback_revision, state.last_action, state.accepted)
		encounter.entry_gates[deck].set_open(state.gate_open(deck) and (deck != 2 or not encounter.king.active))

func capture(live: bool = false) -> Dictionary:
	return CastleSnapshot.capture(self, live)

func restore(data: Dictionary, live: bool = false) -> void:
	CastleSnapshot.restore(self, data, live)
