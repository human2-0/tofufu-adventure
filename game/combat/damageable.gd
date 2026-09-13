class_name Damageable
extends Node3D
## Explicit hit/health contract. Attach to a body or a destructible prop.

signal changed(current: float, maximum: float)
signal hit(amount: float, direction: Vector3)
signal depleted

var trains_weapons: bool = false

@export var maximum: float = 60.0
@export var body: CollisionObject3D
var current: float = 60.0
var invulnerability: float = 0.0

func _ready() -> void:
	current = maximum

func _physics_process(delta: float) -> void:
	invulnerability = maxf(0.0, invulnerability - delta)

func damage(amount: float, direction: Vector3 = Vector3.ZERO) -> bool:
	if current <= 0.0 or invulnerability > 0.0 or amount <= 0.0:
		return false
	current = maxf(0.0, current - amount)
	changed.emit(current, maximum)
	hit.emit(amount, direction)
	if current <= 0.0:
		depleted.emit()
	return true

func heal(amount: float) -> void:
	if current > 0.0:
		current = minf(maximum, current + maxf(0.0, amount))
		changed.emit(current, maximum)

func restore() -> void:
	current = maximum
	invulnerability = 2.0
	changed.emit(current, maximum)

## Local-space upper hit region, configured only on creatures and practice targets.
var headshot_height: float = INF

func is_headshot(point: Vector3) -> bool:
	return body != null and body.to_local(point).y >= headshot_height
