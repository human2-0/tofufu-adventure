class_name GrassResponse
extends Node
## Supplies grounded local and replica contacts to the cosmetic grass map at 20 Hz.

var game: AdventureGame
var _elapsed: float = 0.0
var _previous: Dictionary[int, Vector2] = {}

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 0.05: return
	var field := game.world.grass_imprint
	field.recover(_elapsed)
	var contacts: Dictionary[int, Vector2] = {}
	if game.opening == null or not game.opening.active: _contact(game.player, contacts)
	for peer in game.player.placement_peers:
		if is_instance_valid(peer) and peer is Player and peer != game.player:
			_contact(peer, contacts)
	_previous = contacts
	field.upload()
	_elapsed = 0.0

func _contact(actor: Player, contacts: Dictionary[int, Vector2]) -> void:
	if not actor.is_visible_in_tree() or actor.transport_active: return
	var feet := actor.get_node("PlayerFootsteps") as PlayerFootsteps
	if not feet.grounded(): return
	var at := actor.global_position
	var ground := game.world.ground_point(at.x, at.z)
	if absf(at.y - ground.y) > 0.55: return
	var point := Vector2(at.x, at.z)
	var id := actor.get_instance_id()
	game.world.grass_imprint.press(_previous.get(id, point), point)
	contacts[id] = point
