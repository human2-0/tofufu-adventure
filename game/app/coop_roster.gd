class_name CoopRoster
extends Node
## Owns explicit actor handles, restoration and departure checkpoints.

signal changed
var game: Node3D
var room: PlaytestRoom
var authority: bool = false
var actors: Dictionary[String, Player] = {}
var party: Dictionary[String, CoopActor] = {}
var saved_states: Dictionary = {}
var local_input: PlayerCommandSource
var _world_targets: Array[Damageable] = []

func _ready() -> void:
	_world_targets = game.combat.targets.duplicate()
	local_input = game.player.command_source
	game.player.command_sampled.disconnect(game._on_command)
	game.encounters.experience_awarded.disconnect(game.progression.progress.award_experience)
	game.health.depleted.disconnect(game._respawn)
	game.set_process_unhandled_input(false)
	if authority and room.dedicated:
		game.player.set_physics_process(false)
		game.player.collision_layer = 0
		game.player.hide()
		game.player.placement_peers.erase(game.player)
		game.exploration.explorer = null
		game.combat.process_mode = Node.PROCESS_MODE_DISABLED
		game.combat.sword.hide()
		game.combat.gun.visual.hide()
		game.combat.sotjet.visual.hide()
	_sync()
	room.changed.connect(_sync)

func _sync() -> void:
	if not room.playing: return
	var modified: bool = false
	for key: String in actors.keys():
		if key not in room.members:
			modified = true
			if authority: saved_states[key] = party[key].capture()
			game.player.placement_peers.erase(actors[key])
			party[key].queue_free()
			actors[key].queue_free()
			party.erase(key)
			actors.erase(key)
	for key: String in room.members:
		if not actors.has(key):
			_add(key)
			modified = true
	if not modified: return
	game.exploration.companions.clear()
	for actor: Player in actors.values():
		if actor != game.player: game.exploration.companions.append(actor)
	for member: CoopActor in party.values():
		member.combat.targets = _world_targets.duplicate()
		member.combat.gun.friends.clear()
		for other: CoopActor in party.values():
			if other != member: member.combat.targets.append(other.health)
		member.combat.gun.targets = member.combat.targets
		member.combat.sotjet.flow.targets = member.combat.targets
	changed.emit()

func _add(key: String) -> void:
	var actor: Player = game.player
	var member := CoopActor.new()
	member.authority = authority
	if key != room.local_key:
		actor = preload("res://game/player/player.tscn").instantiate()
		var source := RemotePlayerInput.new()
		actor.add_child(source)
		actor.command_source = source
		game.add_child(actor)
		actor.placement_peers = game.player.placement_peers
		actor.placement_peers.append(actor)
		actor.relocate(Vector3(actors.size() * 1.5, 0.2, 2))
		actor.visuals.modulate = Color("def4d8")
	else:
		member.progression = game.progression
		member.combat = game.combat
		member.health = game.health
		member.hud = game.hud
	member.actor = actor
	if not authority and key == room.local_key:
		member.prediction = CoopPrediction.new()
		member.prediction.actor = actor
	add_child(member)
	member.combat.targets = game.combat.targets
	member.time_requested.connect(func() -> void: game.cycle.phase = fposmod(game.cycle.phase + 0.25, 1.0))
	if authority and saved_states.has(key): member.restore(saved_states[key], game.encounters.experience)
	actors[key] = actor
	party[key] = member
	actor.set_physics_process(authority)
	var label := Label3D.new()
	label.text = "You" if key == room.local_key else str(room.names.get(key, "Fufu"))
	label.font_size = 25
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.6
	actor.add_child(label)

func capture_party() -> Dictionary:
	var data := saved_states.duplicate(true)
	for key: String in party: data[key] = party[key].capture()
	return data
