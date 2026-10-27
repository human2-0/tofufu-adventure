class_name BattleVisibility
extends Node
## Skip offscreen sprite/held-model work; every capsule, weapon and projectile simulates.

var game: BattleRoyaleGame
var _shadows: Array[GroundShadow] = []
const COMBATANT_RANGE: float = 140.0 # Beyond every weapon's reach, inside near cover's hysteresis.

func _ready() -> void:
	process_priority = -18 # After camera follow, before wrist interpolation and weapon views.
	for slot in game.bodies.size():
		limit(game.bodies[slot])
		limit(game.combat.fighters[slot])
		_shadows.append(game.bodies[slot].get_node("GroundShadow") as GroundShadow)
	for fighter in game.combat.fighters:
		fighter.combat.gun.visual_muzzle = _gun_muzzle.bind(fighter)
		fighter.combat.sotjet.flow.visual.nozzle_provider = _jet_muzzle.bind(fighter)
	if DisplayServer.get_name() == "headless": set_process(false)

func _process(_delta: float) -> void:
	var bounds := game.get_viewport().get_visible_rect().grow(160)
	for slot in game.bodies.size():
		var actor := game.bodies[slot]
		var at := actor.global_position + Vector3.UP
		var on_screen := slot == game.watch_slot
		if not on_screen and game.camera.global_position.distance_squared_to(at) < COMBATANT_RANGE * COMBATANT_RANGE and not game.camera.is_position_behind(at):
			on_screen = bounds.has_point(game.camera.unproject_position(at))
		_apply(slot, on_screen and game.match_state.rows[slot][8] > 0)

func _apply(slot: int, enabled: bool) -> void:
	var actor := game.bodies[slot]
	var combat := game.combat.fighters[slot].combat
	if enabled and not actor.visuals.presentation_enabled: actor.visuals.jump_animation.reset()
	actor.visuals.presentation_enabled = enabled
	_shadows[slot].set_active(enabled)
	var rendering := enabled and DisplayServer.get_name() != "headless"
	actor.presentation.set_process(rendering)
	combat.set_process(rendering)
	for view: Node3D in [combat.sword, combat.staff, combat.gun.visual, combat.sotjet.visual, combat.bow.visual]:
		view.set_process(enabled)
	combat.sword.visible = enabled and combat.equipment.knife_owned and combat.equipment.knife_selected
	combat.staff.visible = enabled and combat.equipment.staff_owned and combat.equipment.staff_selected
	combat.gun.visual.visible = enabled and combat.gun.selected
	combat.sotjet.visual.visible = enabled and combat.sotjet.selected
	combat.bow.visual.visible = enabled and combat.bow.selected

func _gun_muzzle(fighter: BattleFighter) -> Vector3:
	var gun := fighter.combat.gun
	return gun.visual.muzzle_position() if fighter.actor.visuals.presentation_enabled else gun.muzzle_position(gun.visual.facing)

func _jet_muzzle(fighter: BattleFighter) -> Vector3:
	var jet := fighter.combat.sotjet
	return jet.visual.muzzle_position() if fighter.actor.visuals.presentation_enabled else jet.muzzle_position(jet.visual.facing)

static func limit(root: Node) -> void:
	if root is GeometryInstance3D:
		var view := root as GeometryInstance3D
		view.visibility_range_end = minf(view.visibility_range_end, COMBATANT_RANGE) if view.visibility_range_end > 0 else COMBATANT_RANGE
	for child in root.get_children(): limit(child)
