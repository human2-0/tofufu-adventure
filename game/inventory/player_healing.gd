class_name PlayerHealing
extends RefCounted
## Manages gradual health recovery and consumable consumption cooldowns.

signal eaten(item_name: String, amount: float)
signal cooldown_updated(remaining: float, total: float)

var equipment: CharacterEquipment
var health: Node

var cooldown_remaining: float = 0.0
var cooldown_total: float = 2.0
var active_heal_remaining: float = 0.0
var active_heal_rate: float = 10.0

func step(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
		cooldown_updated.emit(cooldown_remaining, cooldown_total)
	if active_heal_remaining > 0.0 and health != null and health.has_method("heal") and health.current > 0.0:
		var tick: float = minf(active_heal_remaining, active_heal_rate * delta)
		health.heal(tick)
		active_heal_remaining = maxf(0.0, active_heal_remaining - tick)

func can_use_slot(slot_name: String) -> bool:
	if cooldown_remaining > 0.0 or equipment == null:
		return false
	var stack := equipment.get_slot(slot_name)
	if stack == null or stack.count <= 0 or stack.item == null:
		return false
	if health != null and health.current >= health.maximum:
		return false
	return true

func use_slot(slot_name: String) -> bool:
	if not can_use_slot(slot_name):
		return false
	var stack := equipment.get_slot(slot_name)
	stack.count -= 1
	var heal_amt: float = stack.item.healing_amount
	var duration: float = maxf(0.1, stack.item.heal_duration)
	var cd: float = stack.item.cooldown
	var item_name: String = stack.item.name
	if stack.count <= 0:
		equipment.set_slot(slot_name, null)
	else:
		equipment.changed.emit()
	active_heal_remaining += heal_amt
	active_heal_rate = heal_amt / duration
	cooldown_remaining = cd
	cooldown_total = cd
	cooldown_updated.emit(cooldown_remaining, cooldown_total)
	eaten.emit(item_name, heal_amt)
	return true
