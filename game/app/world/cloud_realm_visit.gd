class_name CloudRealmVisit
extends Node
## Local court greetings; shared residents and terrain have no gameplay state.

var game: AdventureGame

func _process(_delta: float) -> void:
	var npc := game.world.cloud_realm.godfufu
	npc.sprite.view_focus = game.player
	for resident in game.world.cloud_realm.court.residents:
		resident.sprite.view_focus = game.player
		resident.greeting.visible = game.hud.visible and not game.player.transport_active and game.player.global_position.distance_to(resident.global_position) < 5.0
	npc.greeting.visible = game.hud.visible and not game.player.transport_active and game.player.global_position.distance_to(npc.global_position) < 6.0
