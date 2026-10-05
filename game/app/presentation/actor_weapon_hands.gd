class_name ActorWeaponHands
extends RefCounted
## Identical local/remote attachment wiring; player and combat stay independent.

static func connect_visuals(sprite: FufuVisuals, combat: PlayerCombat) -> void:
	for weapon in [combat.sword, combat.staff, combat.gun.visual, combat.sotjet.visual]:
		sprite.hand_presented.connect(weapon.follow_hand)
		sprite.hand_tint_presented.connect(weapon.grip.set_tint)
