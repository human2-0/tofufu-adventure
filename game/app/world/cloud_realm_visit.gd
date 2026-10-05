class_name CloudRealmVisit
extends Node
## Local placeholder greeting presentation; shared terrain needs no mutable state.

var game: AdventureGame

func _process(_delta: float) -> void:
	var npc := game.world.cloud_realm.godfufu
	npc.greeting.visible = game.hud.visible and not game.player.transport_active and game.player.global_position.distance_to(npc.global_position) < 6.0
