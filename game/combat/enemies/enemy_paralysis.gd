class_name EnemyParalysis
extends RefCounted
## Stops intent and attacks while retaining gravity and terrain collisions.

static func hold(body: CharacterBody3D, target: Damageable, delta: float) -> bool:
	if target.paralysis <= 0: return false
	body.velocity = Vector3(0, body.velocity.y - 25 * delta, 0)
	body.move_and_slide()
	return true
