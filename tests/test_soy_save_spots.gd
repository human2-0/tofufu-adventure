extends SceneTree
## Real placement, shared aim focus, ownership, defeat and solo-save contracts.

var failures: int = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int = 3) -> void:
	for i in count:
		await physics_frame
		await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await ticks()
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	game.player.set_physics_process(false)
	var spots := game.soy_spots
	check(spots.spots.size() == 11 and spots.ownership.mask == 0, "eleven meaningful destinations start unowned")
	check(SoySaveSpotSites.IDS.size() == SoySaveSpotSites.POINTS.size() and SoySaveSpotSites.TITLES.size() == 11, "stable IDs and named authored sites align")
	var visited := SoySpotOwnership.new()
	for i in spots.spots.size():
		var plant := spots.spots[i]
		check(not game.world.is_water(plant.position), "save spot is on dry land: " + plant.title)
		check(not VolcanicLava.molten(plant.position), "save spot avoids lava: " + plant.title)
		var floor_query := PhysicsRayQueryParameters3D.create(plant.global_position + Vector3.UP * 0.5, plant.global_position + Vector3.DOWN, 1, [plant.base_body.get_rid()])
		var floor_hit := game.get_world_3d().direct_space_state.intersect_ray(floor_query)
		check(not floor_hit.is_empty() and absf(floor_hit.position.y - plant.position.y) < 0.15, "plant sits on collision surface: " + plant.title)
		var clearance := PhysicsShapeQueryParameters3D.new()
		var space := CylinderShape3D.new()
		space.radius = 0.55
		space.height = 2.2
		clearance.shape = space
		clearance.transform.origin = plant.global_position + Vector3.UP * 1.3
		clearance.collision_mask = 1
		clearance.exclude = [plant.base_body.get_rid()]
		check(game.get_world_3d().direct_space_state.intersect_shape(clearance, 1).is_empty(), "plant does not intersect an existing solid prop: " + plant.title)
		var reachable := false
		for offset in [Vector3(0, 0.1, 1.6), Vector3(1.6, 0.1, 0), Vector3(0, 0.1, -1.6), Vector3(-1.6, 0.1, 0)]:
			game.player.relocate(plant.position + offset)
			if spots.reachable(game.player, i):
				reachable = true
				break
		check(reachable, "collision-aware player can approach: " + plant.title)
		check(spots.perform(game.player, visited, i), "each destination can be claimed from its approach: " + plant.title)
	check(visited.mask == 2047, "all authored ownership bits fit the save/protocol bound")
	check(not spots.perform(game.player, spots.ownership, 0), "out-of-range claiming is rejected")
	check(not spots.perform(game.player, spots.ownership, -1) and not spots.perform(game.player, spots.ownership, 11), "invalid site IDs are rejected")
	game.player.relocate(spots.spots[0].position + Vector3(0, 0.1, 1.6))
	await ticks()
	var source := game.shooting_view.local_input
	source._pointer_aim = true
	game.camera.reset_follow()
	var target := spots.spots[0].global_position + Vector3.UP * 1.4
	WorldInteractionFocus.select_focus(game.world_items, source, game.camera.unproject_position(target))
	check(game.world_items.focused_kind == "soy_spot" and game.world_items.focused_plot == 0, "aim selects the plant through shared interaction focus")
	spots._process(0)
	check(spots.spots[0].prompt.visible and spots.spots[0].prompt.text.contains("Claim"), "unowned focused plant shows the interaction binding")
	var event := InputEventAction.new()
	event.action = "pickup_weapon"
	event.pressed = true
	spots._unhandled_input(event)
	spots._physics_process(0)
	check(spots.ownership.owns(0), "interaction claims the selected plant")
	check(not spots.perform(game.player, spots.ownership, 0), "repeat claim is idempotent")
	spots._process(0)
	check(spots.spots[0].owned and spots.spots[0].halo.visible and spots.spots[0].prompt.text.contains("Owned"), "owned label and gold halo confirm the state")
	var other := SoySpotOwnership.new()
	check(not other.owns(0), "ownership is personal")
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 0.2)
	collision.shape = box
	wall.add_child(collision)
	wall.position = spots.spots[0].position + Vector3(0, 1, 0.8)
	game.add_child(wall)
	await ticks()
	check(not spots.perform(game.player, other, 0), "solid walls block ownership claims")
	wall.queue_free()
	await ticks()
	var save := JSON.parse_string(JSON.stringify(AdventureSnapshot.capture(game, "Soy save spot test", 20))) as Dictionary
	check(SaveStore.valid(save) and save.soy_spots == 1, "JSON solo save captures valid bounded personal ownership")
	spots.ownership.mask = 0
	AdventureSnapshot.restore(game, save)
	check(spots.ownership.owns(0), "solo continuation restores claimed plants")
	game._on_player_depleted()
	check(spots.ownership.owns(0), "defeat does not clear owned spots")
	save.erase("soy_spots")
	check(SaveStore.valid(save), "legacy solo saves remain valid")
	AdventureSnapshot.restore(game, save)
	check(spots.ownership.mask == 0, "legacy solo save starts with no claimed plants")
	for invalid in [-1, 2048, 0.5, "1", true]:
		save.soy_spots = invalid
		check(not SaveStore.valid(save), "malformed solo ownership is rejected: " + str(invalid))
	game.queue_free()
	await process_frame
	print("Soybean save spots: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
