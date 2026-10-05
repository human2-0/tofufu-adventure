class_name GunRunPose
extends RefCounted
## Per-view carry blend shared by the gun, reticle and local aiming ray.

const AIM_DROP: float = 0.14
const PITCH: float = 0.24
var blend: float = 0.0

func step(lowered: bool, delta: float) -> void:
	var target := 1.0 if lowered else 0.0
	blend = lerpf(blend, target, 1.0 - exp(-9.0 * maxf(delta, 0.0)))
	if absf(blend - target) < 0.0001: blend = target

func reset() -> void:
	blend = 0.0

func aim_offset() -> Vector2:
	return Vector2(0.0, AIM_DROP * blend)
