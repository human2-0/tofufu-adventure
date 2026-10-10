class_name PlayerImpact
extends RefCounted
## Pure bounded melee recoil. The host supplies impulses; the motor applies motion.

var remaining: float = 0.0
var push := Vector2.ZERO

func receive(impulse: Vector3) -> void:
	remaining = 0.24
	push = Vector2(impulse.x, impulse.z).limit_length(9.0)

func step(velocity: Vector3, grounded: bool, gravity: float, delta: float) -> Vector3:
	remaining = maxf(0.0, remaining - delta)
	velocity.x = push.x
	velocity.z = push.y
	push = push.move_toward(Vector2.ZERO, 24.0 * delta)
	if not grounded or velocity.y > 0.0: velocity.y -= gravity * delta
	elif velocity.y < 0.0: velocity.y = 0.0
	return velocity

func clear() -> void:
	remaining = 0.0
	push = Vector2.ZERO

func capture() -> Dictionary:
	return {"remaining": remaining, "push": [push.x, push.y]}

func restore(data: Dictionary) -> void:
	remaining = clampf(float(data.get("remaining", 0.0)), 0.0, 0.24)
	var value: Array = data.get("push", [0, 0])
	push = Vector2(value[0], value[1]).limit_length(9.0)
