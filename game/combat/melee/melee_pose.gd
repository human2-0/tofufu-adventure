class_name MeleePose
extends RefCounted
## Shared pose geometry for authority clash samples and weapon/trail rendering.

static func present(combat: PlayerCombat, facing: Vector2, progress: float, heavy: bool) -> void:
	var pose := combat._attack_pose(combat.actor.global_position, facing, progress)
	if combat.equipment.guarding:
		facing = combat.equipment.facing
		pose = SwordGeometry.guard_pose(combat.actor.global_position, facing, combat.tuning)
	var cutting := combat.active and SwordGeometry.cutting(progress, combat.tuning)
	combat.clash.record(pose, cutting)
	var attachment := 1.0
	if combat.active:
		attachment = 1.0 - smoothstep(0.0, combat.tuning.cut_start, progress) if progress < combat.tuning.cut_start else smoothstep(combat.tuning.cut_end, 1.0, progress)
	if combat.equipment.guarding:
		attachment = 0.0
	combat.sword.present(pose, facing, maxf(combat.rules.charge, combat._strength if combat.active else 0.0), cutting, attachment)
	combat.staff.present(pose, combat.rules.charge, combat.active and combat.attack_style == StaffAttack.TORNADO, 0.0 if cutting else attachment)
	combat._trail.record(pose, combat.tuning, cutting, heavy, combat._melee_length())
