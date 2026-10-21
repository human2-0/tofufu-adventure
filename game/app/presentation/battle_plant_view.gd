class_name BattlePlantView
extends Node
## Existing textured soybean props, streamed near the camera; emergence is cosmetic.
const PLANT := preload("res://game/world/common/soy_save_spot.tscn")
var game: BattleRoyaleGame
var plants: Dictionary = {}
var clock: float = 0
var previous_stage: int = -1
var idle := PlayerCommand.new()

func _ready() -> void:
	process_priority = -14 # After actor interpolation, before the weapon hands.

func _process(delta: float) -> void:
	if not game.composed: return
	var state := game.match_state.deployment
	if state.is_empty(): return
	var stage := int(state.stage)
	var changed := previous_stage != stage
	if changed:
		previous_stage = stage
		if stage == 2:
			for actor in game.bodies:
				actor.visuals.scale = Vector3.ONE
				actor.presentation.reset()
	if stage < 2:
		for slot in game.bodies.size():
			var actor := game.bodies[slot]
			if stage == 0:
				actor.hide()
				game.combat.fighters[slot].hide()
			elif stage == 1:
				actor.position = game.match_state.position_of(slot)
				actor.visuals.present(idle, Vector3.ZERO, true, false, delta)
				var site: Array = state.sites[int(state.choices[slot])]
				var progress := smoothstep(0, 1, 1.0 - float(state.remaining) / BattleDeploymentState.EMERGENCE_SECONDS)
				var origin := Vector3(site[0], site[1] + 1.8, site[2]) - actor.position
				actor.visuals.position = Vector3(0, 0.58, 0) + origin * (1 - progress) + Vector3.UP * sin(progress * PI) * 0.4
				actor.visuals.scale = Vector3.ONE * lerpf(0.2, 1.0, minf(1, progress * 3))
				actor.show()
				game.combat.fighters[slot].hide()
	if changed and stage > 0: game.camera.reset_follow()
	clock += delta
	if clock < 0.25 or DisplayServer.get_name() == "headless": return
	clock = 0
	for index in state.sites.size():
		var site: Array = state.sites[index]
		var at := Vector3(site[0], site[1], site[2])
		var nearby := at.distance_squared_to(game.bodies[game.watch_slot].position) < 3600
		if nearby and not plants.has(index):
			_spawn(index, at)
		elif not nearby and plants.has(index):
			plants[index].queue_free()
			plants.erase(index)
		if plants.has(index):
			var reserved := false
			for choice in state.choices:
				if int(choice) == index: reserved = true
			plants[index].present(reserved, false, "")

func _spawn(index: int, at: Vector3) -> void:
	var plant := PLANT.instantiate() as SoySaveSpot
	game.add_child(plant)
	plant.position = at
	# Streaming is cosmetic: the authority's camera must never change world collisions.
	plant.base_body.collision_layer = 0
	plant.base_body.collision_mask = 0
	plants[index] = plant
