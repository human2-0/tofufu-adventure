class_name PlayerRangedSetup
extends RefCounted
## Builds the actor's ranged components before command/equipment wiring.

static func build(combat: PlayerCombat) -> void:
	combat.gun = SoyGun.new()
	combat.gun.actor = combat.actor as CollisionObject3D
	combat.gun.tuning = combat.tuning
	combat.add_child(combat.gun)
	combat.bow = AngelBow.new()
	combat.bow.combat = combat
	combat.add_child(combat.bow)
	combat.sotjet = Sotjet.new()
	combat.sotjet.actor = combat.actor as CollisionObject3D
	combat.add_child(combat.sotjet)
