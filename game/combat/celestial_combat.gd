class_name CelestialCombat
extends RefCounted
## Cosmetic variants share the existing authoritative sword, staff and gun rules.

const ITEMS: Array[String] = ["", "celestial_sword", "celestial_staff", "soy_raygun"]

static func apply(combat: PlayerCombat, kind: int) -> void:
	kind = clampi(kind, 0, 3)
	combat.equipment.celestial_weapon = kind
	combat.sword.set_celestial(kind == 1)
	combat.staff.set_celestial(kind == 2, combat.tuning.staff_length, combat.tuning.grip_length)
	combat.gun.celestial = kind == 3
	combat.gun.visual.set_celestial(kind == 3)

static func item_id(kind: int) -> String:
	return ITEMS[clampi(kind, 0, 3)]
