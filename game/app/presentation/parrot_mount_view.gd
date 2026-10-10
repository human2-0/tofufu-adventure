class_name ParrotMountView
extends Node
## Local presentation of authoritative ridden and parked parrots.

var travel: ParrotTravel
var riders: Dictionary[Player, ParrotArt] = {}
var parked: Dictionary[Player, ParrotArt] = {}

func _ready() -> void:
	process_priority = -8 # After ActorPresentation, before the bird animation.

func _process(_delta: float) -> void:
	var actors: Array[Player] = [travel.game.player]
	if travel.session != null: actors.assign(travel.session.roster.actors.values())
	for actor in actors:
		if actor.transport_active:
			if not riders.has(actor):
				_watch(actor)
				var bird := ParrotArt.new()
				actor.add_child(bird)
				bird.position.y = -travel.SADDLE_HEIGHT
				riders[actor] = bird
			var offset := actor.presentation.ground_position - actor.global_position
			riders[actor].position = actor.global_basis.inverse() * offset - Vector3.UP * travel.SADDLE_HEIGHT
			riders[actor].airborne = true
			riders[actor].heading = actor.velocity
		elif riders.has(actor):
			riders[actor].queue_free()
			riders.erase(actor)
		if actor.parrot_rest.is_finite() and not actor.transport_active:
			if not parked.has(actor):
				_watch(actor)
				var bird := ParrotArt.new()
				add_child(bird)
				parked[actor] = bird
			parked[actor].global_position = (actor.get_parent() as Node3D).to_global(actor.parrot_rest)
		elif parked.has(actor):
			parked[actor].queue_free()
			parked.erase(actor)

func _watch(actor: Player) -> void:
	var callback := _release.bind(actor)
	if not actor.tree_exiting.is_connected(callback): actor.tree_exiting.connect(callback, CONNECT_ONE_SHOT)

func _release(actor: Player) -> void:
	for birds in [riders, parked]:
		if birds.has(actor):
			if is_instance_valid(birds[actor]): birds[actor].queue_free()
			birds.erase(actor)
