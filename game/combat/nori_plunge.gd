class_name NoriPlunge
extends RefCounted
## Per-actor plunge rules; the actor adapter applies velocity through normal collisions.
const COST: float = 75.0
var active: bool = false
var diving: bool = false
var elapsed: float = 0.0
var released: bool = false
var cooldown: float = 0.0
var recovery: float = 0.0
var sequence: int = 0
var impact_at := Vector3.ZERO

func start(combat: PlayerCombat, aim: Vector2) -> void:
	if active or cooldown > 0.0 or not combat.actor is CharacterBody3D: return
	if not combat.vitals.spend(COST): return
	active = true
	var body := combat.actor as CharacterBody3D
	diving = false
	elapsed = 0.0
	released = false
	recovery = 0.0
	cooldown = 2.0
	combat.active = true
	combat.special_attack = true
	combat.attack_aim = SwordGeometry.direction(aim)
	combat.rules.cancel_charge()
	combat.clash.clear()
	combat._trail.record(Transform3D.IDENTITY, combat.tuning, false, false)
	body.velocity = Vector3.UP * 14.0
	NoriPlungeVFX.launch(combat, combat.actor.global_position)

func velocity(current: Vector3, _grounded: bool, delta: float) -> Vector3:
	if not active: return current
	elapsed += delta
	diving = elapsed >= 1.05 or (released and elapsed >= 0.55)
	if diving: return Vector3.DOWN * 24.0
	var steering := Vector2(current.x, current.z).limit_length(5.5)
	return Vector3(steering.x, maxf(0.0, 14.0 * (1.0 - elapsed / 0.7)), steering.y)

func step(combat: PlayerCombat, delta: float) -> void:
	recovery = maxf(0.0, recovery - delta)
	cooldown = maxf(0.0, cooldown - delta)
	if not active: return
	var body := combat.actor as CharacterBody3D
	if body == null or elapsed > 3.0:
		cancel()
		combat.active = false
		return
	if not diving or not body.is_on_floor(): return
	impact_at = body.global_position
	sequence += 1
	recovery = 0.22
	active = false
	combat.active = false
	combat.rules.cooldown = 0.45
	combat.combo.begin_attack()
	var damage := combat.tuning.light_damage * combat.sword_damage_multiplier * 3.0
	var trained := false
	for target in combat.targets:
		if not is_instance_valid(target) or target == combat.owner_health or target.current <= 0: continue
		var offset := target.global_position - impact_at
		if Vector2(offset.x, offset.z).length() > combat.tuning.nori_plunge_radius or absf(offset.y) > 1.5: continue
		if not combat._unobstructed(impact_at, target): continue
		var impulse := Vector3(offset.x, 0, offset.z).normalized() * 7.0 + Vector3.UP * 3.0
		if not target.damage(damage, impulse, Damageable.HitKind.MELEE): continue
		combat.vitals.confirmed_hit(false)
		combat.combo.confirm_hit()
		combat.struck.emit(1.0, 1)
		if target.trains_weapons and not trained:
			trained = true
			combat.weapon_trained.emit("sword")
		CombatEffects.burst(combat, target.global_position, str(int(damage)), Color("a9ffe0"))
	combat.combo.finish_attack()
	combat._emit_combo()
	NoriPlungeVFX.impact(combat, impact_at, combat.tuning.nori_plunge_radius)

func cancel() -> void:
	active = false
	diving = false
	elapsed = 0.0
	recovery = 0.0

static func pose(at: Vector3) -> Transform3D:
	# Local -Z (blade tip) points straight down; the grip stays over the blade.
	return Transform3D(Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP), at + Vector3.UP * 1.0 + Vector3.BACK * 0.35)
