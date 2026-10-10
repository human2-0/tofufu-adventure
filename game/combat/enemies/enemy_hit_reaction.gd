class_name EnemyHitReaction
extends RefCounted
## Bounded physical stagger and disposable visual recoil, owned by each enemy.

var stagger: float = 0.0
var pause: float = 0.0
var recoil: float = 0.0
var lean: float = 1.0

func receive(direction: Vector3, kind: Damageable.HitKind) -> void:
	var melee := kind in [Damageable.HitKind.KNIFE, Damageable.HitKind.MELEE]
	stagger = 0.24 if melee else 0.12
	if direction.y > 0.0: stagger = 0.42
	pause = (0.06 if direction.y > 0.0 or direction.length() > 6.0 else 0.04) if melee else 0.0
	flash(direction)

func flash(direction: Vector3 = Vector3.ZERO) -> void:
	recoil = 1.0
	lean = -1.0 if direction.x < 0.0 else 1.0

func step(delta: float) -> bool:
	var frozen := pause > 0.0
	pause = maxf(0.0, pause - delta)
	if not frozen: stagger = maxf(0.0, stagger - delta)
	return frozen

func present(visual: Node3D, delta: float) -> void:
	if recoil <= 0.0: return
	recoil = maxf(0.0, recoil - delta * 5.0)
	visual.scale = Vector3(1.0 + recoil * 0.12, 1.0 - recoil * 0.12, 1.0)
	visual.rotation.z = lean * recoil * 0.14

func clear() -> void:
	stagger = 0.0
	pause = 0.0
	recoil = 0.0
