class_name CurrencyExchange
extends RefCounted
## Exact, lossless currency upgrades. Inventory authority owns every call.

const RATE: int = 100
const NEXT_TIER := {
	"edamame": "mature_bean",
	"mature_bean": "tofu_white_chunk",
	"tofu_white_chunk": "toasted_tofu_chunk",
	"toasted_tofu_chunk": "golden_tofu_chunk",
}

static func required_count(source_id: String) -> int:
	return 1 if source_id == "mature_bean" else RATE

static func convert(inventory: PlayerInventory, slot: int, source_id: String) -> String:
	if inventory == null or not NEXT_TIER.has(source_id): return "That currency cannot be refined."
	if not inventory.refining_unlocked: return "Refining is illegal until Tofu Dungeon is complete."
	if slot < 0 or slot >= inventory.capacity: return "Invalid backpack slot."
	var stack := inventory.get_slot(slot)
	if stack == null or stack.item == null or stack.item.id != source_id:
		return "Currency changed; try again."
	var cost := required_count(source_id)
	if stack.count < cost: return "Need %d %s in this stack." % [cost, stack.item.name]
	if stack.count > RATE or (cost == RATE and stack.count != RATE) or stack.item.category != "currency" or stack.item.max_stack != RATE:
		return "Invalid currency stack."
	var target: InventoryItem = InventoryItem.currency(NEXT_TIER[source_id])
	if target == null: return "That currency cannot be refined."
	var output_count := stack.count if source_id == "mature_bean" else 1
	# One mutation replaces the selected stack; no intermediate debit or overflow.
	inventory.set_slot(slot, ItemStack.new(target, output_count))
	return "Refined %d %s into %d %s." % [stack.count, stack.item.name, output_count, target.name]
