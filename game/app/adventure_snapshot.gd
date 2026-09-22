class_name AdventureSnapshot
extends RefCounted
## Composition translates scene state into persistence values; no node serialization.

static func capture(game: Node3D, title: String, seconds: float) -> Dictionary:
	game.loadout.persist_reserve()
	var position: Vector3 = game.player.position
	var equipment: PlayerEquipment = game.combat.equipment
	var dropped := equipment.dropped.global_position if is_instance_valid(equipment.dropped) else Vector3.ZERO
	return {"version": 1, "name": title, "saved_at": Time.get_datetime_string_from_system(),
		"opening_complete": game.opening == null or not game.opening.active,
		"position": [position.x, position.y, position.z], "health": game.health.current,
		"phase": game.cycle.phase, "seconds": seconds, "beans": game.encounters.beans,
		"weather_phase": game.weather.phase,
		"mobs": game.encounters.mobs, "props": game.encounters.props, "experience": game.encounters.experience,
		"progression": game.progression.progress.capture(), "discoveries": game.exploration.found_places(), "knife_owned": equipment.knife_owned,
		"sotjet_selected": game.combat.sotjet.selected, "soymilk": game.combat.sotjet.milk, "gun_selected": game.combat.gun.selected, "knife_selected": equipment.knife_selected, "dropped_position": [dropped.x, dropped.y, dropped.z],
		"gun_owned": equipment.gun_owned, "sotjet_owned": equipment.sotjet_owned,
		"world_items": game.world_items.pool.capture(),
		"coins": game.inventory.coins, "active_slot": game.loadout.active_slot,
		"pending_items": game.inventory.pending_items.map(func(stack: ItemStack) -> Dictionary: return stack.capture()),
		"inventory": game.inventory.capture() if game.inventory != null else [],
		"quest": game.quest_giver.quest.capture() if game.quest_giver != null else {},
		"equipment": game.character_equipment.capture() if game.character_equipment != null else {}}

static func restore(game: Node3D, data: Dictionary) -> void:
	if data.opening_complete:
		game.player.relocate(Vector3(data.position[0], data.position[1], data.position[2]))
		game.camera.global_position = game.player.position + game.camera.offset
	game.progression.progress.restore(data.get("progression", {}), int(data.experience))
	game.health.current = maxf(1, data.health)
	game.hud.show_health(game.health.current, game.health.maximum)
	game.cycle.phase = data.phase
	game.weather.set_phase(float(data.get("weather_phase", 0.0)))
	for field in ["beans", "mobs", "props", "experience"]:
		game.encounters.set(field, int(data[field]))
	game.hud.show_progress(int(data.beans), int(data.mobs), int(data.props))
	game.hud.show_experience(int(data.experience))
	game.exploration.restore_places(data.discoveries)
	game.combat.equipment.restore_save(data.knife_owned, data.knife_selected,
		Vector3(data.dropped_position[0], data.dropped_position[1], data.dropped_position[2]))

	game.combat.gun.selected = data.get("gun_selected", false)
	game.combat.sotjet.selected = data.get("sotjet_selected", false)
	game.combat.sotjet.milk = data.get("soymilk", game.combat.sotjet.tuning.capacity)
	if data.has("inventory") and game.inventory != null: game.inventory.restore(data.get("inventory", []))
	if data.has("quest") and game.quest_giver != null: game.quest_giver.quest.restore(data.get("quest", {}))

	game.combat.equipment.gun_owned = data.get("gun_owned", true)
	game.combat.equipment.sotjet_owned = data.get("sotjet_owned", true)
	if data.has("world_items"):
		game.world_items.pool.restore(data.world_items)
	elif not data.knife_owned:
		# Version-1 saves stored the sole knife on the actor.
		var at := Vector3(data.dropped_position[0], data.dropped_position[1], data.dropped_position[2]) + Vector3.UP * 0.4
		game.world_items.pool.restore([[1, "knife", 1, 100, at.x, at.y, at.z]])

	game.inventory.coins = int(data.get("coins", 10))
	game.inventory.restore_pending(data.get("pending_items", []))
	game.loadout.restore(data.get("equipment", {}), int(data.get("active_slot", 1)), {"owned": data.knife_owned, "gun_owned": data.get("gun_owned", true), "sotjet_owned": data.get("sotjet_owned", true), "gun": data.get("gun_selected", false), "jet": data.get("sotjet_selected", false), "milk": data.get("soymilk", 100)})
