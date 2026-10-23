class_name AngelArrow
extends Node3D
## Swept high-speed arrow. Damage and the flame pulse are authority-only.

var bow: AngelBow
var authoritative: bool = true
var empowered: bool = false
var velocity := Vector3.ZERO
var targets: Array[Damageable] = []
var ignored: Array[CollisionObject3D] = []
var body_damage: float = 50.0
var head_damage: float = 100.0
var remaining: float = 1.25
var initial_start := Vector3.ZERO
var _first: bool = true
var flight: AngelArrowView

func _ready() -> void:
	flight = AngelArrowView.new()
	flight.empowered = empowered
	add_child(flight)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func place(at: Vector3) -> void:
	global_position = at
	flight.place(at, velocity)

func _physics_process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		queue_free()
		return
	var end := global_position + velocity * delta
	var excluded: Array[RID] = []
	var actor := bow.combat.actor as CollisionObject3D
	if is_instance_valid(actor): excluded.append(actor.get_rid())
	for body in ignored:
		if is_instance_valid(body): excluded.append(body.get_rid())
	var space := get_world_3d().direct_space_state
	var hit: Dictionary = {}
	if _first: hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(initial_start, global_position, 3, excluded))
	_first = false
	if hit.is_empty(): hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, end, 3, excluded))
	if hit.is_empty():
		global_position = end
		flight.advance(end)
		return
	if authoritative: resolve(hit.collider, hit.position + hit.normal * 0.025)
	queue_free()

func resolve(body: Object, at: Vector3) -> void:
	if not authoritative: return
	var struck: Damageable
	for target in targets:
		if not is_instance_valid(target) or target.body != body: continue
		struck = target
		var amount := head_damage if target.is_headshot(at) else body_damage
		if empowered: amount *= 2.0
		if target.receive_attack(amount, velocity.normalized() * 3.0, Damageable.HitKind.SOY, at, bow.combat.owner_health):
			credit(target, at, amount, not empowered)
		break
	if empowered:
		bow.impact(at)
		AngelFlameSphere.pulse(self, at, struck)
	else:
		CombatEffects.sparks(bow, at)

func credit(target: Damageable, at: Vector3, amount: float, normal: bool) -> void:
	CombatEffects.burst(bow, at, str(roundi(amount)), Color("ffce70"))
	if is_instance_valid(bow.combat.owner_health): bow.combat.owner_health.attack_confirmed.emit(normal)
	if target.trains_weapons: bow.combat.weapon_trained.emit("shooting")
