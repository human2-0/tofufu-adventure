class_name FactoryCargoPose
extends RefCounted
## Keeps a held prop beside the actor, with restrained movement-only presentation.

static func apply(prop: Node3D, owner: int, actors: Dictionary, clock: float) -> void:
	var data: Variant = actors.get(owner, actors.get(str(owner)))
	var sack: bool = str(prop.name).begins_with("sack_")
	var scale: float = 0.55 if owner > 0 and data is Dictionary and sack else 1.0
	if float(prop.get_meta("factory_carried_scale", 1.0)) != scale:
		prop.set_meta("factory_carried_scale", scale)
		prop.scale = Vector3.ONE * scale
	if owner <= 0:
		if sack: prop.rotation = Vector3.ZERO
		return
	if data is Vector3:
		prop.global_position = data + Vector3(0, 0.7, 0.6)
	elif data is Dictionary and data.get("position") is Vector3:
		var direction: Vector2 = data.get("facing", Vector2.DOWN)
		var forward := Vector3(direction.x, 0, direction.y).normalized()
		var side := Vector3(forward.z, 0, -forward.x)
		var moving: bool = bool(data.get("moving", false))
		var bob: float = sin(clock * 9.0) * 0.025 if moving else 0.0
		var offset: Vector3 = forward * 0.3 + side * 0.5 + Vector3(0, 0.18 + bob, 0) if sack else forward * 0.45 + side * 0.28 + Vector3(0, 0.45 + bob, 0)
		prop.global_position = data.position + offset
		if sack:
			prop.rotation = Vector3(0, atan2(forward.x, forward.z), sin(clock * 9.0) * 0.025 if moving else 0)
