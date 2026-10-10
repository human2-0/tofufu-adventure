class_name KnifeAttack
extends RefCounted
## Immutable knife move selection and authored properties; PlayerCombat owns its runtime state.

enum Style { SLASH, STAB, HEAVY, AIR_SLASH, LAUNCHER, TORNADO, REVERSE_SLASH }

static func select(strength: float, combo_active: bool, airborne: bool, tuning: CombatTuning, chain_count: int = 1) -> int:
	if airborne:
		return Style.AIR_SLASH
	if strength >= 1.0:
		return Style.LAUNCHER if combo_active else Style.HEAVY
	if combo_active and strength * tuning.charge_seconds <= tuning.combo_stab_hold_seconds:
		match chain_count % 4:
			1: return Style.REVERSE_SLASH
			2: return Style.STAB
			3: return Style.LAUNCHER
	return Style.SLASH

static func duration(style: int, tuning: CombatTuning) -> float:
	if style == Style.REVERSE_SLASH: return tuning.combo_reverse_seconds
	if style == Style.STAB: return tuning.combo_stab_seconds
	if style == Style.AIR_SLASH: return tuning.air_slash_seconds
	if style == Style.LAUNCHER: return tuning.launcher_seconds
	return tuning.heavy_swing_seconds if style == Style.HEAVY else tuning.swing_seconds

static func pose(style: int, at: Vector3, aim: Vector2, progress: float, tuning: CombatTuning) -> Transform3D:
	if style == Style.LAUNCHER and progress >= 0.0:
		return MeleeArc.pose(at, aim, progress, tuning, style)
	if style == Style.REVERSE_SLASH and progress >= 0.0:
		return MeleeArc.pose(at, aim, progress, tuning, style)
	if style == Style.STAB and progress >= 0.0:
		return SwordGeometry.stab_pose(at, aim, progress, tuning)
	if style == Style.AIR_SLASH and progress >= 0.0:
		return SwordGeometry.dive_pose(at, aim, progress, tuning)
	return SwordGeometry.pose(at, aim, progress, tuning, powered(style))

static func damage(style: int, tuning: CombatTuning, charged: bool = true) -> float:
	if style == Style.STAB: return tuning.combo_stab_damage
	if style == Style.AIR_SLASH: return tuning.air_slash_damage
	if style == Style.LAUNCHER: return tuning.launcher_damage if charged else tuning.combo_launcher_damage
	return tuning.heavy_damage if style == Style.HEAVY else tuning.light_damage

static func impulse(style: int, aim: Vector2, tuning: CombatTuning) -> Vector3:
	var forward := Vector3(aim.x, 0, aim.y)
	if style == Style.LAUNCHER: return forward * 2.5 + Vector3.UP * tuning.launcher_lift
	if style == Style.AIR_SLASH: return forward * 5.0 + Vector3.DOWN * 3.0
	return forward * (9.0 if style == Style.HEAVY else (2.5 if style == Style.STAB else 1.8))

static func powered(style: int) -> bool:
	return style == Style.HEAVY or style == Style.LAUNCHER
