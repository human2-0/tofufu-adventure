class_name DungeonCrateSupply
extends RefCounted
## Authored finite crates share persisted identities across restarts and loads.

static func ensure(dungeon: TofuDungeon) -> void:
	for room in mini(int(dungeon.puzzle.stage) + 1, 6):
		for slot in 2:
			var identity: int = room * 2 + slot
			if dungeon.state.crate_broken(identity) or _exists(dungeon, identity): continue
			var crate := FactoryCrate.new()
			crate.set_meta("factory_crate_id", identity)
			crate.position = TofuFactory.CENTERS[room] + Vector3(-8 if slot == 0 else 8, 0, 6)
			dungeon.game.world.add_child(crate)
			crate.broken.connect(dungeon._crate_broken.bind(crate, identity))
			dungeon._register_target(crate.target)
			dungeon._crates.append(crate)

static func _exists(dungeon: TofuDungeon, identity: int) -> bool:
	for crate: FactoryCrate in dungeon._crates:
		if is_instance_valid(crate) and crate.get_meta("factory_crate_id", -1) == identity: return true
	return false
