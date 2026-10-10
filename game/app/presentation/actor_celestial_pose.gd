class_name ActorCelestialPose
extends Node
## Reads actor/combat presentation context without changing their rules or state.

var combat: PlayerCombat
var _last_health: float = -1.0
var _hurt_remaining: float = 0.0

func _process(delta: float) -> void:
	_hurt_remaining = maxf(0.0, _hurt_remaining - delta)
	if combat.owner_health == null: return
	var health: float = combat.owner_health.current
	if _last_health >= 0.0 and health < _last_health: _hurt_remaining = 0.24
	_last_health = health

func context() -> Dictionary:
	var player := combat.actor as Player
	if player != null and player.transport_active: return {"action": "riding"}
	if _hurt_remaining > 0.0: return {"action": "hurt"}
	if combat.gun.selected:
		return {"action": "reload" if combat.gun.reload_remaining > 0.0 else "aim"}
	if combat.equipment.guarding: return {"action": "guard"}
	if combat.equipment._punch_time > 0.18: return {"action": "thrust"}
	if combat.active:
		var progress: float = combat._elapsed / combat._attack_duration()
		if progress < 0.22 or progress > 0.78: return {"action": "windup"}
		return {"action": "thrust" if combat.attack_style == KnifeAttack.Style.STAB else "cut"}
	if combat.rules.charge > 0.0: return {"action": "windup"}
	return {}
