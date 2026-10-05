class_name DungeonInteraction
extends RefCounted
## Actor/station interactions and carried-sack presentation values.

static func connect_actor(dungeon: TofuDungeon, actor: Player) -> void:
	if not is_instance_valid(actor) or actor in dungeon._connected: return
	dungeon._connected.append(actor)
	actor.command_sampled.connect(dungeon._command.bind(actor))

static func command(dungeon: TofuDungeon, command: PlayerCommand, _delta: float, actor: Player) -> void:
	if dungeon.puzzle_enabled and dungeon.cooperative and actor != dungeon.game.player: return
	if command.pickup_pressed and (dungeon.enabled or actor == dungeon.game.player): dungeon.interact(actor)

static func interact(dungeon: TofuDungeon, actor: Player) -> bool:
	if not dungeon.enabled or not TofuFactory.contains(actor.global_position) or dungeon.state.completed or not dungeon.state.active: return false
	if dungeon.state.action_remaining > 0 or dungeon.state.process_remaining > 0 or (not dungeon.state.secured and dungeon.state.stage != 3): return false
	if dungeon.state.stage == 0 or dungeon.state.stage == 2:
		if not dungeon._carrying.has(actor):
			for i in range(dungeon.state.units, mini(3, dungeon.state.units + 1)):
				if actor.global_position.distance_to(TofuFactory.bag(i, dungeon.state.stage)) < 2.2:
					if i in dungeon._carrying.values(): return false
					dungeon._carrying[actor] = i
					dungeon.game.hud.announce("Carrying soy sack · [E] at the hopper to deliver")
					return true
			return false
		if actor.global_position.distance_to(TofuFactory.station(dungeon.state.stage)) > 2.8: return false
		dungeon._carrying.erase(actor)
	elif actor.global_position.distance_to(TofuFactory.station(dungeon.state.stage)) > 2.8:
		return false
	var added := dungeon.state.operate()
	if added: dungeon.game.hud.announce("%s · %d / %d" % [TofuDungeonState.STATIONS[dungeon.state.stage], dungeon.state.units, dungeon.state.required_units()])
	if added and dungeon.state.stage == 3:
		# Adding nigari awakens the curds; production cannot finish until they fall.
		dungeon._spawn_stage()
		dungeon.game.hud.announce("Nigari added! Dofu are climbing out of the milk!")
	return added

static func cargo_positions(dungeon: TofuDungeon) -> Array:
	var result: Array = []
	for actor: Player in dungeon._carrying:
		if not is_instance_valid(actor): continue
		var at := actor.global_position
		result.append([at.x,at.y,at.z])
	return result
