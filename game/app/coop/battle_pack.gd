class_name BattlePack
extends RefCounted
## Temporary inventories and authoritative world loot, scoped to this match only.

var game: BattleRoyaleGame
var healing: Array[PlayerHealing] = []
var revisions: Array[int] = []
var transactions := BattlePackActions.new()
var requests := BattlePackRequests.new()
var field := BattleChestField.new()
var next_drop: int = 0
var _dead: Dictionary = {}
var snapshots: Array = []

func build() -> void:
	transactions.pack = self
	requests.pack = self
	field.game = game
	for fighter in game.combat.fighters:
		var heal := PlayerHealing.new()
		heal.equipment = fighter.loadout.equipment
		heal.health = fighter.health
		heal.vitals = fighter.combat.vitals
		healing.append(heal)
		revisions.append(1)
		snapshots.append([])
		fighter.loadout.equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack("factory_backpack"), 1))
		fighter.loadout.equipment.set_slot("support_1", ItemStack.new(InventoryItem.soy_milk(), 1))
		fighter.loadout.equipment.set_slot("support_2", ItemStack.new(InventoryItem.apple(), 2))
		var outfit := BattleOutfitView.new()
		outfit.fighter = fighter
		game.add_child(outfit)
	step(0)
	capture()

func capture(force: bool = false) -> void:
	game.match_state.pack = BattlePackSnapshot.capture(self, force)

func refresh(slot: int) -> void:
	var fighter := game.combat.fighters[slot]
	var row: Array = game.match_state.rows[slot]
	row[22] = BattleItems.weapon_kind(fighter.loadout.equipment.get_slot("combat_1"))
	row[23] = BattleItems.weapon_kind(fighter.loadout.equipment.get_slot("combat_2"))
	row[10] = row[21 + fighter.loadout.active_slot]
	row[18] = fighter.loadout.active_slot
	fighter._gear = [int(row[22]), int(row[23]), int(row[10]), int(row[18])]
	fighter.loadout.refresh(false)
	fighter.gear_refreshed.emit()
	revisions[slot] += 1

func step(delta: float) -> void:
	for slot in game.bodies.size():
		var fighter := game.combat.fighters[slot]
		var row: Array = game.match_state.rows[slot]
		if row[8] <= 0:
			if not _dead.has(slot):
				_dead[slot] = true
				transactions.drop_all(slot)
			continue
		if game.match_state.winner != -2: continue
		fighter.health.current = float(row[8])
		healing[slot].step(delta)
		row[8] = fighter.health.current
		var total := 0
		for stack in fighter.loadout.inventory.slots:
			if stack != null and stack.item.category == "support": total += stack.count
		for name in ["support_1", "support_2", "support_3", "support_4"]:
			var stack := fighter.loadout.equipment.get_slot(name)
			if stack != null: total += stack.count
		row[16] = total

func spawn(stack: ItemStack, at: Vector3) -> bool:
	if stack == null: return false
	var drops := game.match_state.drops
	var entry := [next_drop, snappedf(at.x, 0.001), snappedf(at.y, 0.001), snappedf(at.z, 0.001), BattlePackWire.ITEMS.find(stack.item.id) + 1, stack.count, snappedf(stack.reserve, 0.001)]
	for i in drops.size():
		if drops[i][5] == 0:
			drops[i] = entry
			next_drop += 1
			return true
	if drops.size() >= BattlePackWire.DROPS: return false
	drops.append(entry)
	next_drop += 1
	return true

func reachable(slot: int, at: Vector3, chest: int = -1) -> bool:
	var body := game.bodies[slot]
	if body.position.distance_squared_to(at) > 12.25: return false
	var excludes: Array[RID] = []
	if chest >= 0 and chest < field.blockers.size(): excludes.assign(field.blockers[chest])
	var ray := PhysicsRayQueryParameters3D.create(body.position + Vector3.UP * 0.8, at + Vector3.UP * 0.5, 1, excludes)
	return body.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func drop_point(slot: int, offset: Vector3) -> Vector3:
	var body := game.bodies[slot]
	var at := body.position + offset
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.8, at - Vector3.UP * 5, 1)
	var floor_hit := body.get_world_3d().direct_space_state.intersect_ray(ray)
	var point: Vector3 = floor_hit.position + Vector3.UP * 0.05 if not floor_hit.is_empty() else game.world.ground_point(at.x, at.z, 0.05)
	return point if reachable(slot, point) else body.position

func interact_bot(slot: int) -> void:
	for chest: Array in game.match_state.chests:
		if chest[4] == 0 and reachable(slot, Vector3(chest[1], chest[2], chest[3]), int(chest[0])):
			BattleChestLoot.open(self, slot, int(chest[0]))
			return
	for drop: Array in game.match_state.drops:
		if drop[5] > 0 and reachable(slot, Vector3(drop[1], drop[2], drop[3])):
			if not BattlePackBots.wants(game.match_state.pack[slot], int(drop[4])): continue
			if transactions.take(slot, int(drop[0])):
				BattlePackBots.equip(self, slot)
				return

func restore(values: Array) -> void:
	requests.clear()
	_dead.clear()
	next_drop = 0
	for drop: Array in game.match_state.drops: next_drop = maxi(next_drop, int(drop[0]) + 1)
	for slot in game.bodies.size():
		if game.match_state.rows[slot][8] <= 0: _dead[slot] = true
	BattlePackSnapshot.apply(self, values, true)
	field.update(false)

func dispose() -> void:
	# Break RefCounted helper cycles when leaving a match.
	requests.clear()
	requests.pack = null
	transactions.pack = null
	field.game = null
	healing.clear()
	snapshots.clear()
	game = null
