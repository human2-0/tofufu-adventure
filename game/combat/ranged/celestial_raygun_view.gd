class_name CelestialRaygunView
extends Node3D
## A solid, all-angle celestial gun follows the same wrist and reload presentation.

var model: Node3D

func _ready() -> void:
	model = preload("res://game/combat/models/soy_raygun.tscn").instantiate() as Node3D
	add_child(model)

func present(hand: Vector3, facing: Vector2, camera: Camera3D, in_front: bool, reload_seconds: float, lowering: float, kick: float) -> void:
	var forward := Vector3(facing.x, 0, facing.y).normalized()
	if forward.is_zero_approx(): forward = Vector3.BACK
	var basis := Basis.looking_at(forward, Vector3.UP)
	basis *= Basis(Vector3.BACK, SoyGunReloadPose.roll(reload_seconds))
	basis *= Basis(Vector3.RIGHT, -0.24 * lowering)
	global_basis = basis
	global_position = hand + camera.global_basis.z * (0.04 if in_front else -0.04)
	global_position -= camera.global_basis.y * (SoyGunReloadPose.weight(reload_seconds) * 0.16 + lowering * 0.08)
	global_position += camera.global_basis.y * SoyGunReloadPose.feed(reload_seconds) * 0.05
	global_position -= forward * kick * 0.025

func muzzle_position() -> Vector3:
	return to_global(Vector3(0, 0.1, -0.55))
