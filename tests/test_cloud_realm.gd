extends SceneTree
## Reach the realm by real parrot flight, land, walk, save and take off again.

class CloudInput extends PlayerCommandSource:
	var move := Vector2.ZERO
	var rise: bool = false
	func sample(_at: Vector3) -> PlayerCommand:
		var command := PlayerCommand.new()
		command.move = move
		command.jump_held = rise
		return command

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for tick in count: await physics_frame

func _run() -> void:
	var game: AdventureGame = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.encounters.process_mode = Node.PROCESS_MODE_DISABLED
	await ticks(4)
	game.progression.progress.award_experience(CharacterProgress.threshold(8, true))
	var court := game.world.cloud_realm.court
	check(court.residents.size() == 12 and court.angels.size() == 12, "court has the Goddess, six sentries, four servants, a merchant and twelve angels")
	var cloud_area: int = 0
	for z in range(236, 364):
		for x in range(-82, 78):
			if CloudTerrain.contains(Vector2(x, z)): cloud_area += 1
	check(cloud_area > 6500, "expanded kingdom has substantially more walkable cloud area")
	var travel := game.parrot_travel
	var input := CloudInput.new()
	game.player.add_child(input)
	game.player.command_source = input
	check((game.world.cloud_realm.godfufu.sprite.texture as AtlasTexture).atlas == Godfufu.ART, "Godfufu uses the generated directional tofu block atlas")
	check(game.world.map_npcs.has("Cloud Realm · Godfufu (above jungle)"), "the elevated destination is named on the map")
	check(game.world.map_npcs.has("Tofufu Goddess · Cloud Court"), "the Goddess appears on the world map")
	game.player.relocate(court.goddess.global_position + Vector3(0, 0.1, 2))
	await ticks(10)
	await process_frame
	check(court.goddess.greeting.visible, "the Goddess welcomes nearby visitors")
	check(court.goddess.has_node("ResidentBody"), "the Goddess has shared world collision")
	game.player.relocate(travel.perches.stations[0].global_position + Vector3(0, 0.1, 3))
	await ticks(3)
	var departure := game.player.position
	check(travel.start(game.player), "jungle parrot boards normally")
	input.rise = true
	await ticks(450)
	input.rise = false
	check(game.player.position.y > CloudTerrain.ALTITUDE + 10, "parrot can climb above the high cloud terrain")
	input.move = Vector2.DOWN
	await ticks(31)
	input.move = Vector2.ZERO
	await ticks(25)
	var floor_at := ParrotLanding.surface(game, game.player)
	check(floor_at.is_finite() and floor_at.y >= CloudTerrain.ALTITUDE - 1, "landing queries find the clouds above jungle ground")
	var airborne := AdventureSnapshot.capture(game, "Cloud flight", 0)
	check(Vector3(airborne.position[0], airborne.position[1], airborne.position[2]).is_equal_approx(departure), "in-flight save retains the safe jungle departure")
	check(travel.request_land(game.player), "cloud surface accepts parrot landing")
	await ticks(330)
	check(not game.player.transport_active and game.player.is_on_floor() and game.player.position.y > 57, "landing restores grounded walking on the actual cloud mesh")
	check(travel.available(game.player), "the landed bird remains available for return travel")
	var landed := AdventureSnapshot.capture(game, "Cloud landing", 0)
	check(SaveStore.valid(landed) and landed.parrot_rest.size() == 3 and landed.position[1] > 57, "landed actor and parked parrot persist at cloud elevation")
	var before := game.player.position
	input.move = Vector2.DOWN
	await ticks(75)
	input.move = Vector2.ZERO
	await ticks(10)
	check(game.player.position.z > before.z + 4 and game.player.is_on_floor(), "walking crosses the rippled landing ribbon")
	for at in [Vector2(5, 268), Vector2(19, 271), Vector2(-22, 272), Vector2(-33, 275), Vector2(-4, 284), Vector2(0, 295), Vector2(42, 288), Vector2(-57, 299), Vector2(6, 333), Vector2(-40, 339), Vector2(46, 333)]:
		check(game.player.relocate(CloudTerrain.point(at.x, at.y, 0.15)), "cloud paths have clearance")
		await ticks(14)
		check(game.player.is_on_floor() and game.player.position.y > 57, "satellite islands and bridges support real actor collisions at %s (actor %s)" % [at, game.player.position])
	game.player.relocate(game.world.cloud_realm.godfufu.global_position + Vector3(0, 0.1, 3))
	await ticks(10)
	await process_frame
	check(game.world.cloud_realm.godfufu.greeting.visible, "Godfufu greets visitors locally")
	var trader := court.merchant
	game.player.relocate(trader.global_position + Vector3(0, 0.1, 2))
	await ticks(8)
	check(game.merchant.nearby(game.player), "royal merchant is reachable on its actual cloud island")
	check(game.merchant.focus_position(game.player).distance_to(trader.global_position) < 2, "aim focus selects Nimbus in the clouds")
	var bag := PlayerInventory.new()
	check(game.merchant.purchase(game.player, bag, "knife").begins_with("Bought") and bag.count_item("knife") == 1, "Nimbus trades equipment using the existing transaction rules")
	check(game.merchant.sell(game.player, bag, 0, "knife").begins_with("Sold") and bag.count_item("mature_bean") == 1, "royal merchant accepts combat gear sales")
	game.player.relocate(game.world.ground_point(trader.position.x, trader.position.z, 0.1))
	await ticks(3)
	check(not game.merchant.nearby(game.player), "royal trade cannot be accessed from the jungle directly below")
	check(not game.merchant.purchase(game.player, bag, "knife").begins_with("Bought"), "distant purchase does not grant equipment")
	AdventureSnapshot.restore(game, landed)
	await ticks(4)
	check(travel.available(game.player) and game.player.position.y > 57, "loading a cloud save retains a reachable return bird")
	check(travel.start(game.player), "cloud bird remounts after restoring a save")
	before = game.player.position
	await ticks(60)
	check(game.player.position.y > before.y + 4, "remounting lifts from the cloud instead of targeting jungle altitude")
	input.move = Vector2.UP
	await ticks(65)
	input.move = Vector2.ZERO
	await ticks(20)
	check(game.player.position.z < 238, "rider can leave the cloud landing island for the jungle below")
	check(travel.request_land(game.player), "return flight can request jungle landing from cloud height")
	await ticks(720)
	check(not game.player.transport_active and game.player.is_on_floor() and game.player.position.y < 10, "return flight descends safely to jungle ground")
	game._respawn()
	await ticks(3)
	game.player.parrot_rest = Vector3.INF
	game.player.relocate(game.world.ground_point(CloudTerrain.LANDING.x, CloudTerrain.LANDING.y, 0.1))
	await ticks(3)
	check(not travel.available(game.player), "the cloud perch cannot be boarded from jungle ground below")
	check(ParrotLanding.surface(game, game.player).y < 10, "floor queries below clouds retain jungle ground")
	game.queue_free()
	for frame in 5: await process_frame
	print("Cloud Realm: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
