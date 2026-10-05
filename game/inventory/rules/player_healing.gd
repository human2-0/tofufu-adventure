class_name PlayerHealing
extends RefCounted
## Manages gradual health recovery and consumable consumption cooldowns.

signal eaten(item_name: String, amount: float)
signal cooldown_updated(remaining: float, total: float)

const APPLE_DURATION_PER_STACK: float = 25.0
const APPLE_MAX_STACKS: int = 5
const APPLE_MAX_DURATION: float = APPLE_DURATION_PER_STACK * APPLE_MAX_STACKS
const APPLE_REGEN_RATE: float = 2.0

var equipment: CharacterEquipment
var health: Node
var vitals: RefCounted

var cooldown_remaining: float = 0.0
var cooldown_total: float = 2.0
var active_heal_remaining: float = 0.0
var active_heal_rate: float = 10.0
var apple_duration_remaining: float = 0.0

func step(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
		cooldown_updated.emit(cooldown_remaining, cooldown_total)
	if active_heal_remaining > 0.0 and health != null and health.has_method("heal") and health.current > 0.0:
		var tick: float = minf(active_heal_remaining, active_heal_rate * delta)
		health.heal(tick)
		active_heal_remaining = maxf(0.0, active_heal_remaining - tick)
	if apple_duration_remaining > 0.0:
		var tick_time := minf(apple_duration_remaining, delta)
		apple_duration_remaining = maxf(0.0, apple_duration_remaining - delta)
		var regen := APPLE_REGEN_RATE * tick_time
		if health != null and health.has_method("heal") and health.current > 0.0:
			health.heal(regen)
		if vitals != null and "current" in vitals and "maximum" in vitals:
			vitals.current = minf(vitals.maximum, vitals.current + regen)

func can_consume_apple() -> bool:
	return apple_duration_remaining < APPLE_MAX_DURATION - 0.01

func consume_apple() -> bool:
	if not can_consume_apple():
		return false
	apple_duration_remaining = minf(APPLE_MAX_DURATION, apple_duration_remaining + APPLE_DURATION_PER_STACK)
	eaten.emit("Apple", 50.0)
	return true

func can_use_slot(slot_name: String) -> bool:
	if cooldown_remaining > 0.0 or equipment == null:
		return false
	var stack := equipment.get_slot(slot_name)
	if stack == null or stack.count <= 0 or stack.item == null or stack.item.category not in ["healing", "consumable", "support"] or stack.item.healing_amount <= 0:
		return false
	if stack.item.id == "apple":
		return can_consume_apple()
	if health != null and health.current >= health.maximum:
		return false
	return true

func use_slot(slot_name: String) -> bool:
	if not can_use_slot(slot_name):
		return false
	var stack := equipment.get_slot(slot_name)
	stack.count -= 1
	var is_apple: bool = stack.item.id == "apple"
	var heal_amt: float = stack.item.healing_amount
	var duration: float = maxf(0.1, stack.item.heal_duration)
	var cd: float = stack.item.cooldown
	var item_name: String = stack.item.name
	if stack.count <= 0:
		equipment.set_slot(slot_name, null)
	else:
		equipment.changed.emit()
	cooldown_remaining = cd
	cooldown_total = cd
	cooldown_updated.emit(cooldown_remaining, cooldown_total)
	if is_apple:
		apple_duration_remaining = minf(APPLE_MAX_DURATION, apple_duration_remaining + APPLE_DURATION_PER_STACK)
		eaten.emit(item_name, heal_amt)
	else:
		active_heal_remaining += heal_amt
		active_heal_rate = heal_amt / duration
		eaten.emit(item_name, heal_amt)
	return true

func consume_from_bag(inventory: PlayerInventory, slot: int) -> bool:
	if inventory == null or slot < 0 or slot >= inventory.capacity:
		return false
	var stack := inventory.get_slot(slot)
	if stack == null or stack.item == null or stack.count <= 0:
		return false
	if stack.item.id == "apple":
		if not can_consume_apple():
			return false
		stack.count -= 1
		if stack.count <= 0:
			inventory.set_slot(slot, null)
		else:
			inventory.changed.emit()
		return consume_apple()
	elif stack.item.category in ["healing", "consumable", "support"] and stack.item.healing_amount > 0:
		if health != null and health.current >= health.maximum:
			return false
		stack.count -= 1
		var heal_amt: float = stack.item.healing_amount
		var duration: float = maxf(0.1, stack.item.heal_duration)
		var item_name: String = stack.item.name
		if stack.count <= 0:
			inventory.set_slot(slot, null)
		else:
			inventory.changed.emit()
		active_heal_remaining += heal_amt
		active_heal_rate = heal_amt / duration
		eaten.emit(item_name, heal_amt)
		return true
	return false
