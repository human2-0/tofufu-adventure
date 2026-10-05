class_name SoyGunReloadPose
extends RefCounted
## Cosmetic pose sampled from the authoritative reload clock in every camera mode.

static func progress(remaining: float) -> float:
	return clampf(1.0 - remaining / SoyGun.RELOAD_SECONDS, 0.0, 1.0)

static func weight(remaining: float) -> float:
	if remaining <= 0.0: return 0.0
	var phase := progress(remaining)
	return smoothstep(0.0, 0.18, phase) * (1.0 - smoothstep(0.78, 1.0, phase))

static func roll(remaining: float) -> float:
	return weight(remaining) * (-0.6 + sin(progress(remaining) * TAU) * 0.1)

static func feed(remaining: float) -> float:
	var phase := progress(remaining)
	return smoothstep(0.25, 0.45, phase) * (1.0 - smoothstep(0.65, 0.85, phase)) * weight(remaining)
