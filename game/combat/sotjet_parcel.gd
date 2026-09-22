class_name SotjetParcel
extends RefCounted
## One emitted volume of milk; launch velocity is retained when the weapon turns.

var excluded_body: CollisionObject3D
var reflected_by: Damageable
var reflections: int = 0
var visual_offset := Vector3.ZERO
var position: Vector3
var velocity: Vector3
var previous: Vector3
var age: float = 0.0
var sequence: int = 0
var burst: int = 0

func advance(delta: float, gravity: float) -> void:
	previous = position
	position += velocity * delta + Vector3.DOWN * gravity * delta * delta * 0.5
	velocity.y -= gravity * delta
	age += delta
