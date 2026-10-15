class_name FirstPersonEnhancementView
extends RefCounted
## Camera-space orbit centered on the selected rendered weapon.

static func center(view: FirstPersonWeapon) -> Vector3:
	var at := Vector3(0, 0.08, 0.04)
	if view.combat.equipment.knife_selected:
		var point: Vector3 = WeaponModelCatalog.TIPS[view._melee_item_id] * 0.5
		at = view._rig.to_local(view._melee_model.to_global(point))
	elif view.combat.equipment.staff_selected:
		at = view._rig.to_local(view._staff._model.to_global(Vector3(0, 0.65, 0)))
	elif view.combat.sotjet.selected:
		at = view._rig.to_local(view._jet.model_grip_position().lerp(view._jet.muzzle_position(), 0.5))
	elif view.combat.gun.celestial:
		at = view._raygun.position + Vector3(0, 0.1, -0.25)
	at.z += 0.08
	return view._rig.to_global(at)
