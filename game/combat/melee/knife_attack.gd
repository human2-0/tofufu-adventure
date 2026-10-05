class_name KnifeAttack
extends RefCounted
## Immutable knife move selection and authored properties; PlayerCombat owns its runtime state.

enum Style { SLASH, STAB, HEAVY, AIR_SLASH, LAUNCHER }

static func select(strength: float, combo_active: bool, airborne: bool, tuning: CombatTuning) -> int:
	if airborne:
		return Style.AIR_SLASH
	if strength >= 1.0:
		return Style.LAUNCHER if combo_active else Style.HEAVY
	if combo_active and strength * tuning.charge_seconds <= tuning.combo_stab_hold_seconds:
		return Style.STAB
	return Style.SLASH

static func duration(style: int, tuning: CombatTuning) -> float:
	if style == Style.STAB: return tuning.combo_stab_seconds
	if style == Style.AIR_SLASH: return tuning.air_slash_seconds
	if style == Style.LAUNCHER: return tuning.launcher_seconds
	return tuning.heavy_swing_seconds if style == Style.HEAVY else tuning.swing_seconds

static func pose(style: int, at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning) -> Transform3D:
	if style == Style.STAB and progress >= 0.0:
		return SwordGeometry.stab_pose(at, aim, progress, tuning)
	if style == Style.AIR_SLASH and progress >= 0.0:
		return SwordGeometry.dive_pose(at, aim, progress, tuning)
	return SwordGeometry.pose(at, aim, progress, tuning, powered(style))

static func damage(style: int, tuning: CombatTuning) -> float:
	if style == Style.STAB: return tuning.combo_stab_damage
	if style == Style.AIR_SLASH: return tuning.air_slash_damage
	if style == Style.LAUNCHER: return tuning.launcher_damage
	return tuning.heavy_damage if style == Style.HEAVY else tuning.light_damage

static func impulse(style: int, aim: Vector2, tuning: CombatTuning) -> Vector3:
	var forward := Vector3(aim.x, 0, aim.y)
	if style == Style.LAUNCHER: return forward * 4.0 + Vector3.UP * tuning.launcher_lift
	if style == Style.AIR_SLASH: return forward * 5.0 + Vector3.DOWN * 3.0
	return forward * (12.0 if style == Style.HEAVY else (8.0 if style == Style.STAB else 5.0))

static func powered(style: int) -> bool:
	return style == Style.HEAVY or style == Style.LAUNCHER
