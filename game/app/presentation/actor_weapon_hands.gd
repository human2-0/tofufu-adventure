class_name ActorWeaponHands
extends RefCounted
## Identical local/remote attachment wiring; player and combat stay independent.

static func connect_visuals(sprite: FufuVisuals, combat: PlayerCombat) -> void:
	var celestial := ActorCelestialPose.new()
	celestial.combat = combat
	combat.add_child(celestial)
	sprite.celestial_pose = celestial.context
	var base_height := sprite.position.y
	combat.render_position = func() -> Vector3: return sprite.global_position - Vector3.UP * base_height
	for weapon in [combat.sword, combat.staff, combat.gun.visual, combat.sotjet.visual]:
		sprite.hand_presented.connect(weapon.follow_hand)
		sprite.hand_tint_presented.connect(weapon.grip.set_tint)
