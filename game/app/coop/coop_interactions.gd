class_name CoopInteractions
extends RefCounted
## Compose authority adapters for inventory, Grandma quests and nursery interactions.

static func build(session: CoopSession) -> void:
	var stats := CoopStatAllocation.new()
	stats.session = session
	session.add_child(stats)
	session.game.inventory_window.drop_requested.disconnect(session.game.world_items._queue_bag_drop)
	session.inventory_sync = CoopInventory.new()
	session.inventory_sync.session = session
	session.add_child(session.inventory_sync)
	var quests := CoopQuests.new()
	quests.session = session
	session.add_child(quests)
	session.farming = CoopFarming.new()
	session.farming.session = session
	session.add_child(session.farming)
	var parrots := CoopParrotTravel.new()
	parrots.session = session
	session.add_child(parrots)
	var soy_spots := CoopSoySaveSpots.new()
	soy_spots.session = session
	session.add_child(soy_spots)
	var apples := CoopAppleHarvest.new()
	apples.session = session
	session.add_child(apples)
	if session.room.dedicated:
		session.connection_health = CoopConnectionHealth.new()
		session.connection_health.session = session
		session.add_child(session.connection_health)
		session.personal_maps = CoopPersonalMaps.new()
		session.personal_maps.session = session
		session.add_child(session.personal_maps)
