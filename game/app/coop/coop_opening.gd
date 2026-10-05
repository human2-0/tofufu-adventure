class_name CoopOpening
extends Node
## The party shares the existing pod quest; only the host advances its rules.

var game: Node3D
var roster: CoopRoster
var authority: bool = false
var _combined: PartyOpeningInput

func _ready() -> void:
	if game.opening == null: return
	game.opening.completed.connect(_completed)
	if authority:
		game.opening.rules.feedback = "Work together: any bean can push or hold Jump."
		_combined = PartyOpeningInput.new()
		add_child(_combined)
		game.player.command_source = _combined
	else:
		game.opening.set_physics_process(false)
	roster.changed.connect(_sync)
	_sync()

func active() -> bool:
	return game.opening != null and game.opening.active

func _sync() -> void:
	if not active(): return
	if _combined != null:
		_combined.sources.clear()
		_combined.sources.append(roster.local_input)
	for key: String in roster.party:
		var member := roster.party[key]
		member.actor.set_physics_process(false)
		member.actor.collision_layer = 0
		member.set_process(false)
		member.set_physics_process(false)
		member.combat.sword.hide()
		member.combat.staff.hide()
		if member.actor != game.player:
			member.actor.hide()
			if _combined != null: _combined.sources.append(member.actor.command_source)

func capture() -> Dictionary:
	return game.opening.capture_state() if game.opening != null else {"active": false}

func apply(state: Dictionary) -> void:
	if game.opening != null: game.opening.apply_state(state)

func _completed() -> void:
	if authority:
		game.player.command_source = roster.local_input
		_combined.queue_free()
		_combined = null
	for key: String in roster.party:
		var member := roster.party[key]
		member.actor.show()
		member.actor.collision_layer = 2
		member.set_process(true)
		member.set_physics_process(true)
		member.actor.set_physics_process(authority)
		member.combat.sword.visible = member.combat.equipment.knife_selected
		member.combat.staff.visible = member.combat.equipment.staff_selected
		if authority and member.actor != game.player:
			member.actor.relocate(game.player.position + Vector3(roster.actors.keys().find(key) * 1.4, 0.1, 0))
	if not authority: CoopWorld.disable_simulation(game)
