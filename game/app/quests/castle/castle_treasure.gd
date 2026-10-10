class_name CastleTreasure
extends RefCounted
## Host-only atomic grants; opened scenery is shared and claims remain per character.

var flow: CastleAdventure

func chest(index: int) -> CastleTreasureChest:
	return flow.castle.floors[index / 4].chests[index % 4]

func claim(actor: Player, index: int) -> bool:
	if index < 0 or index >= 12 or actor not in flow.party.actors() or not flow.reachable(actor, index + 13): return false
	var key := flow.party.key(actor)
	if not flow.authoritative or flow.state.treasure_claimed(key, index): return false
	var member := flow.party.member_for(actor)
	var inventory: PlayerInventory = member.inventory if member != null else flow.game.inventory
	var item := InventoryItem.from_id("golden_tofu_chunk")
	if not inventory.has_space_for(item, 3):
		flow.state.message = "Treasure waits. Make room for three Golden Tofu chunks."
		flow.state.revision += 1
		return false
	if not flow.state.claim_treasure(key, index): return false
	inventory.add_item(item, 3)
	flow.state.message = "Hidden treasure: three Golden Tofu chunks."
	return true

func present(animate: bool) -> void:
	var key := flow.party.key(flow.game.player)
	for index in 12:
		chest(index).present(flow.state.opened_chests & (1 << index) != 0, not flow.state.treasure_claimed(key, index), animate)
