class_name CoopEncounterMotion
extends Node
## Bounded guest movement between unchanged 10-Hz authoritative mob updates.
## This component never runs AI, collision attacks, health or loot rules.

var game: AdventureGame
var _views: Dictionary[TrainingMob, Dictionary] = {}
var _before: Dictionary[TrainingMob, Vector3] = {}
var _age: float = 0.0

func _ready() -> void:
	process_physics_priority = -10

func before_snapshot() -> void:
	for mob: TrainingMob in game.encounters.mob_nodes:
		_before[mob] = mob.position

func accept() -> void:
	_age = 0.0
	for mob: TrainingMob in game.encounters.mob_nodes:
		var previous: Dictionary = _views.get(mob, {})
		var error: Vector3 = _before.get(mob, mob.position) - mob.position
		if previous.is_empty() or previous.alive != mob.visible or error.length_squared() > 25:
			error = Vector3.ZERO
		var view := {"at": mob.position, "velocity": mob.velocity, "error": error, "alive": mob.visible}
		if mob is WildBee:
			view.sting = mob.sting.global_position
			view.sting_velocity = mob.sting.velocity
			view.sting_remaining = mob.sting.remaining
		_views[mob] = view
	_before.clear()

func _physics_process(delta: float) -> void:
	_age = minf(_age + delta, 0.1)
	for mob: TrainingMob in _views:
		var view: Dictionary = _views[mob]
		if not view.alive: continue
		mob.position = view.at + view.velocity * _age + view.error * exp(-30.0 * _age)
		if mob is WildBee and view.sting_remaining > 0:
			mob.sting.global_position = view.sting + view.sting_velocity * minf(_age, view.sting_remaining)
			mob.sting.visible = _age < view.sting_remaining
