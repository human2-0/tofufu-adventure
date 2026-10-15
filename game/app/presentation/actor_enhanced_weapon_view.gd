class_name ActorEnhancedWeaponView
extends Node
## Places the cosmetic upgrade marker on the actual rendered held weapon.

var combat: PlayerCombat
var orbit := MagicalTofufuOrbit.new()

func _ready() -> void:
	orbit.center = _center
	orbit.enabled = func() -> bool: return combat.equipment.weapon_enhanced and (combat.equipment.melee_selected() or combat.ranged_selected())
	add_child(orbit)

func _center() -> Vector3:
	if combat.gun.selected:
		if combat.gun.celestial: return combat.gun.visual.celestial_view.global_position.lerp(combat.gun.visual.muzzle_position(), 0.5)
		return combat.gun.visual.global_position.lerp(combat.gun.visual.muzzle_position(), 0.5)
	if combat.sotjet.selected:
		return combat.sotjet.visual.model_grip_position().lerp(combat.sotjet.visual.muzzle_position(), 0.5)
	if combat.equipment.staff_selected:
		return combat.staff._model.to_global(Vector3(0, 0.65, 0))
	return combat.sword.model_guard_position().lerp(combat.sword.model_tip_position(), 0.5)
