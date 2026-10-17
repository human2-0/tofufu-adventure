class_name AdventureWorldSetup
extends RefCounted
## Ordered world interactions and their local presentation.

static func build(game: AdventureGame) -> void:
	game.parrot_travel = ParrotTravel.new()
	game.parrot_travel.game = game
	game.add_child(game.parrot_travel)
	var volcanic_visit := VolcanicVisit.new()
	volcanic_visit.game = game
	game.add_child(volcanic_visit)
	game.castle_adventure = CastleAdventure.new()
	game.castle_adventure.game = game
	game.add_child(game.castle_adventure)
	var cloud_visit := CloudRealmVisit.new()
	cloud_visit.game = game
	game.add_child(cloud_visit)
	game.soy_spots = SoySaveSpots.new()
	game.soy_spots.game = game
	game.add_child(game.soy_spots)
	game.farming = SoybeanFarming.new()
	game.farming.game = game
	game.add_child(game.farming)
	for npc: Node3D in [game.world.quest_npc, game.world.weapon_merchant]:
		(npc.get_node("DirectionalArt") as MeadowResidentArt).view_focus = game.player
	for resident: DofufuResident in game.world.dofufu_highlands.city.residents.values():
		resident.view_focus = game.player
	game.world.dofufu_highlands.retreat.view_focus = game.player
	game.world.dofufu_highlands.retreat.hermit.view_focus = game.player
	var interiors := MeadowInteriorView.new()
	interiors.actor = game.player
	interiors.camera = game.camera
	interiors.buildings = game.world.interiors
	game.add_child(interiors)
	game.apple_harvest = AppleHarvest.new()
	game.apple_harvest.setup(game)
	game.add_child(game.apple_harvest)
	game.solo_arena = SoloArena.new()
	game.solo_arena.game = game
	game.add_child(game.solo_arena)
