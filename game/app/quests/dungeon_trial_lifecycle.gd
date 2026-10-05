class_name DungeonTrialLifecycle
extends RefCounted
## Damage is an authority interruption, distinct from voluntarily abandoning a press.

static func bind(dungeon: TofuDungeon, actor: Player, health: Damageable) -> void:
	health.hit.connect(func(_amount: float, _direction: Vector3) -> void:
		if not dungeon.enabled: return
		var owner: int = DungeonMembership.actor_id(dungeon, actor)
		dungeon.puzzle.press.release_lease(owner)
		if dungeon.puzzle.phase == TofuPuzzleContract.Phase.OPERATING and dungeon.puzzle.press.active_sample < 0:
			dungeon.puzzle.phase = TofuPuzzleContract.Phase.READY)

static func cancel_local_controls(dungeon: TofuDungeon) -> void:
	dungeon.game.combat.reset()
	dungeon.game.player.motor.cancel_jump()
	dungeon.game.player.motor.cancel_dash_charge()

static func step(dungeon: TofuDungeon) -> void:
	var press: TofuPressRules = dungeon.puzzle.press
	if press.active_sample < 0: return
	for actor: Node3D in dungeon._actors_inside():
		if DungeonMembership.actor_id(dungeon, actor as Player) != press.lease_actor: continue
		var station: String = "modern_press" if press.active_sample == TofuPressRules.Sample.EXTRA_FIRM else "traditional_press"
		if actor.global_position.distance_to(TofuFactory.object_position(station)) > DungeonPuzzleRuntime.INTERACTION_RANGE:
			dungeon.puzzle.abandon_press(press.lease_actor)
		return
