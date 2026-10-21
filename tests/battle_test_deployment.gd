class_name BattleTestDeployment
extends RefCounted
## Gameplay fixtures finish deployment explicitly; selection has its own scenario.

static func finish(game: BattleRoyaleGame) -> void:
	if game.match_state.deployment.is_empty(): return
	BattleDeploymentState.complete(game.match_state.deployment, game.room.options)
	assert(BattlePlantLayout.emerge(game))
	game.match_state.deployment.stage = 2
	game.match_state.deployment.remaining = 0.0
	game.match_state.time = BattleRing.GRACE
	game.combat.process_mode = Node.PROCESS_MODE_INHERIT
