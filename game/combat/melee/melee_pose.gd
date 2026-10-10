class_name MeleePose
extends RefCounted
## Shared pose geometry for authority clash samples and weapon/trail rendering.

static func display_elapsed(combat: PlayerCombat) -> float:
	if combat.replica_view or combat.hit_pause > 0.0: return combat._elapsed
	return lerpf(combat._previous_elapsed, combat._elapsed, Engine.get_physics_interpolation_fraction())

static func render(combat: PlayerCombat) -> void:
	if not is_instance_valid(combat.actor): return
	if combat.replica_view or combat.plunge.active or combat.plunge.recovery > 0.0: return
	if not combat.active and not combat.equipment.guarding: return
	var progress := -1.0
	if combat.active:
		progress = display_elapsed(combat) / combat._attack_duration()
	var at: Vector3 = combat.render_position.call() if combat.render_position.is_valid() else combat.actor.global_position
	present(combat, combat.attack_aim if combat.active else combat._presentation_facing, progress, KnifeAttack.powered(combat.attack_style), at, false)

static func present(combat: PlayerCombat, facing: Vector2, progress: float, heavy: bool, at: Vector3 = Vector3.INF, contact: bool = true) -> void:
	if not at.is_finite(): at = combat.actor.global_position
	var pose := combat._attack_pose(at, facing, progress)
	if combat.equipment.guarding:
		facing = combat.equipment.facing
		pose = SwordGeometry.guard_pose(at, facing, combat.tuning)
	var cutting := combat.active and SwordGeometry.cutting(progress, combat.tuning)
	if contact: combat.clash.record(pose, cutting)
	var attachment := 1.0
	if combat.active:
		attachment = 1.0 - smoothstep(0.0, combat.tuning.cut_start, progress) if progress < combat.tuning.cut_start else smoothstep(combat.tuning.cut_end, 1.0, progress)
	if combat.equipment.guarding:
		attachment = 0.0
	combat.sword.present(pose, facing, maxf(combat.rules.charge, combat._strength if combat.active else 0.0), cutting, attachment)
	combat.staff.present(pose, combat.rules.charge, combat.active and combat.attack_style == StaffAttack.TORNADO, 0.0 if cutting else attachment)
	if contact: combat._trail.record(pose, combat.tuning, cutting, heavy, combat._melee_length())
