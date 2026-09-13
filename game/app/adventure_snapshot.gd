class_name AdventureSnapshot
extends RefCounted
## Composition translates scene state into persistence values; no node serialization.

static func capture(game: Node3D, title: String, seconds: float) -> Dictionary:
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
		"gun_selected": game.combat.gun.selected, "knife_selected": equipment.knife_selected, "dropped_position": [dropped.x, dropped.y, dropped.z]}

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
