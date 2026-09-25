class_name WorldItems
extends Node
## Wires shared world drops to actor equipment, local focus, and inventory grants.

const DEATH_DROP_CHANCE: float = 0.10
const NAMES := {"knife": "Knife", "soy_gun": "Soybean gun", "sotjet": "Sotjet", "sproutwood_staff": "Sproutwood Staff", "factory_backpack": "Factory Backpack", "seed_satchel": "Seed Satchel · +4 slots", "traveler_backpack": "Soypod Backpack", "edamame": "Edamame", "mature_bean": "Mature Bean", "tofu_white_chunk": "White Tofu Chunk", "toasted_tofu_chunk": "Toasted Tofu Chunk", "golden_tofu_chunk": "Golden Tofu Chunk", "piece_of_shell": "Piece of Shell", "soy_milk": "Soy Milk", "bright_leaf_helmet": "Soypod Helmet", "bright_leaf_armor": "Soypod Armor", "bright_leaf_legs": "Soypod Legs", "bright_leaf_boots": "Soypod Boots", "dark_leaf_helmet": "Nori Helmet", "dark_leaf_armor": "Nori Armor", "dark_leaf_legs": "Nori Legs", "dark_leaf_boots": "Nori Boots"}

signal backpack_claimed(item_id: String)
var game: Node3D
var pool := WorldItemPool.new()
var focused_id: int = 0
var focused_kind: String = ""
var focused_plot: int = -1
var _inventories: Dictionary = {}
var _loadouts: Dictionary = {}
var _bag_drops: Array = []
var death_roll: Callable = func() -> float: return randf()

func _ready() -> void:
	pool.build_visual = WorldItemVisuals.build
	add_child(pool)
	register(game.combat, game.inventory, game.loadout)
	game.inventory_window.drop_requested.connect(_queue_bag_drop)

func register(combat: PlayerCombat, inventory: PlayerInventory, loadout: ActorLoadout = null) -> void:
	_loadouts[combat] = loadout
	if not _inventories.has(combat):
		combat.tree_exiting.connect(func() -> void:
			_inventories.erase(combat)
			_loadouts.erase(combat))
	_inventories[combat] = inventory
	combat.equipment.drop_item = _drop_weapon.bind(combat)
	combat.equipment.pickup_item = _pickup.bind(combat)

func _drop_weapon(combat: PlayerCombat) -> bool:
	if not pool.authoritative: return false
	var gear := combat.equipment
	var id := "sotjet" if combat.sotjet.selected else ("soy_gun" if combat.gun.selected else ("sproutwood_staff" if gear.staff_selected else ("knife" if gear.knife_selected else "")))
	if id.is_empty() or not _owns(combat, id): return false
	var drop := pool.spawn(id, 1, combat.actor.global_position, gear.facing, combat.sotjet.milk if id == "sotjet" else 100.0)
	if drop == null:
		if combat == game.combat: game.hud.announce("No room to drop / Step away from the obstacle")
		return false
	gear.dropped = drop
	var loadout: ActorLoadout = _loadouts.get(combat)
	if loadout != null: loadout.equipment.set_slot("combat_%d" % loadout.active_slot, null)
	else: _set_owned(combat, id, false)
	combat.reset()
	return true

func spawn_mob_loot(item_id: String, at: Vector3) -> bool:
	if not pool.authoritative: return false
	return pool.spawn(item_id, 1, at, Vector2.RIGHT) != null

func _pickup(id: int, combat: PlayerCombat) -> bool:
	if not pool.authoritative: return false
	if id < 0: id = pool.focused(combat.actor.global_position, combat.equipment.facing)
	var drop: WorldItemDrop = pool.drops.get(id)
	if drop == null or not pool.reachable(drop, combat.actor.global_position): return false
	var inventory: PlayerInventory = _inventories.get(combat)
	var item := InventoryItem.from_id(drop.item_id)
	if inventory == null or item == null: return false
	if item.category == "backpack":
		var claimed := _pickup_backpack(drop, combat, inventory)
		if claimed: backpack_claimed.emit(drop.item_id)
		return claimed
	if item.category != "combat":
		var remaining := inventory.add_item(item, drop.count)
		if remaining == drop.count: return false
		drop.count = remaining
		if remaining == 0: pool.remove(id)
		return true
	var loadout: ActorLoadout = _loadouts.get(combat)
	if loadout == null: return false
	var stack := ItemStack.new(item, 1)
	stack.reserve = drop.reserve
	if not loadout.receive(stack): return false
	pool.remove(id)
	return true

func _pickup_backpack(drop: WorldItemDrop, combat: PlayerCombat, inventory: PlayerInventory) -> bool:
	var loadout: ActorLoadout = _loadouts.get(combat)
	if loadout == null: return false
	var worn := loadout.equipment.get_slot("backpack")
	if worn == null:
		loadout.equipment.set_slot("backpack", ItemStack.new(InventoryItem.backpack(drop.item_id), 1))
		inventory.restore(drop.contents)
		pool.remove(drop.drop_id)
		return true
	if _backpack_empty(drop):
		if inventory.add_item(InventoryItem.backpack(drop.item_id), 1) != 0: return false
		pool.remove(drop.drop_id)
		return true
	var taken := false
	for index in drop.contents.size():
		var row: Variant = drop.contents[index]
		if not row is Dictionary or row.is_empty(): continue
		var stack := ItemStack.restore(row)
		if stack == null: continue
		var remaining := inventory.add_item(stack.item, stack.count)
		if remaining < stack.count: taken = true
		if remaining == 0: drop.contents[index] = {}
		else:
			var remainder := stack.capture()
			remainder.count = remaining
			drop.contents[index] = remainder
	if not taken: return false
	if _backpack_empty(drop) and inventory.add_item(InventoryItem.backpack(drop.item_id), 1) == 0:
		pool.remove(drop.drop_id)
	return true

func _backpack_empty(drop: WorldItemDrop) -> bool:
	for row: Variant in drop.contents:
		if row is Dictionary and not row.is_empty(): return false
	return true

func _owns(combat: PlayerCombat, id: String) -> bool:
	if id == "knife": return combat.equipment.knife_owned
	if id == "soy_gun": return combat.equipment.gun_owned
	if id == "sotjet": return combat.equipment.sotjet_owned
	return combat.equipment.staff_owned

func _set_owned(combat: PlayerCombat, id: String, value: bool) -> void:
	if id == "knife":
		combat.equipment.knife_owned = value
		if not value: combat.equipment.knife_selected = false
	elif id == "soy_gun":
		combat.equipment.gun_owned = value
		if not value: combat.gun.selected = false
	elif id == "sotjet":
		combat.equipment.sotjet_owned = value
		if not value: combat.sotjet.selected = false
	elif id == "sproutwood_staff":
		combat.equipment.staff_owned = value
		if not value: combat.equipment.staff_selected = false

func _process(_delta: float) -> void:
	var previous := focused_id
	focused_id = 0
	focused_kind = ""
	focused_plot = -1
	var source: LocalPlayerInput = game.shooting_view.local_input if game.shooting_view != null else null
	if source != null and source.enabled and not source.chat_blocked and game.hud.visible and not get_tree().paused:
		_select_focus(source)
	if source != null: source.pickup_target = focused_id
	if pool.drops.has(previous): pool.drops[previous].set_focus(false, "")
	if not pool.drops.has(focused_id): return
	var drop := pool.drops[focused_id]
	var action := "Pick up"
	var binding := GamePreferences.binding_text("pickup_weapon", "keyboard")
	var title: String = NAMES.get(drop.item_id, drop.item_id)
	if drop.count > 1: title += " ×%d" % drop.count
	var item := InventoryItem.from_id(drop.item_id)
	if item != null and item.category != "backpack" and not game.inventory.has_space_for(item, 1):
		drop.set_focus(true, "Bag full · " + title)
	else: drop.set_focus(true, "[%s] %s %s" % [binding, action, title])

func _select_focus(source: LocalPlayerInput) -> void:
	var origin: Vector3 = game.player.global_position
	var camera := get_viewport().get_camera_3d()
	var pointer := get_viewport().get_visible_rect().size * 0.5 if source.shoulder_view else get_viewport().get_mouse_position()
	var best := INF
	for id: int in pool.drops:
		var drop: WorldItemDrop = pool.drops[id]
		if not pool.reachable(drop, origin): continue
		var score := _focus_score(drop.global_position + Vector3.UP * 0.45, origin, source, camera, pointer)
		if score < best:
			best = score
			focused_kind = "drop"
			focused_id = id
	if game.quest_giver != null and game.quest_giver.nearby(game.player):
		best = _consider("quest", game.world.quest_npc.global_position + Vector3(0, 1.5, 0.65), origin, source, camera, pointer, best)
	if game.merchant != null and game.merchant.nearby(game.player):
		best = _consider("merchant", game.world.weapon_merchant.global_position + Vector3(0, 1.5, 0.65), origin, source, camera, pointer, best)
	if game.seed_storage != null and game.seed_storage.nearby(game.player):
		best = _consider("storage", game.world.seed_bank.global_position + Vector3(0, 1.25, 1.5), origin, source, camera, pointer, best)
	if game.farming != null and game.farming.available():
		for index in game.farming.plots.size():
			var plot: SoybeanPlot = game.farming.plots[index]
			if not game.farming.reachable(game.player, plot): continue
			var score := _focus_score(plot.global_position + Vector3.UP * 0.5, origin, source, camera, pointer)
			if score < best:
				best = score
				focused_kind = "plot"
				focused_id = 0
				focused_plot = index

func _consider(kind: String, at: Vector3, origin: Vector3, source: LocalPlayerInput, camera: Camera3D, pointer: Vector2, best: float) -> float:
	var score := _focus_score(at, origin, source, camera, pointer)
	if score < best:
		focused_kind = kind
		focused_id = 0
		focused_plot = -1
		return score
	return best

func _focus_score(at: Vector3, origin: Vector3, source: LocalPlayerInput, camera: Camera3D, pointer: Vector2) -> float:
	var offset := Vector2(at.x - origin.x, at.z - origin.z)
	var distance := offset.length()
	if source.pointer_focus() and camera != null:
		if camera.is_position_behind(at): return INF
		return camera.unproject_position(at).distance_to(pointer) / get_viewport().get_visible_rect().size.y + distance * 0.01
	var alignment := source.focus_direction().normalized().dot(offset.normalized()) if distance > 0.01 else 1.0
	return (1.0 - alignment) * 2.0 + distance * 0.3

func _queue_bag_drop(source: String, id: Variant) -> void:
	if pool.authoritative and _bag_drops.size() < 16: _bag_drops.append([source, id])

func _physics_process(_delta: float) -> void:
	for row: Array in _bag_drops: drop_stack(game.combat, game.inventory, game.character_equipment, row[0], row[1])
	_bag_drops.clear()
	# Legacy saves with full bags recover overflow without destroying weapons.
	if pool.authoritative:
		for combat: PlayerCombat in _inventories:
			var inv: PlayerInventory = _inventories[combat]
			if not inv.pending_items.is_empty():
				var stack: ItemStack = inv.pending_items[0]
				if pool.spawn(stack.item.id, stack.count, combat.actor.global_position, combat.equipment.facing, stack.reserve) != null: inv.pending_items.pop_front()

func drop_stack(combat: PlayerCombat, inventory: PlayerInventory, equipment: CharacterEquipment, source: String, id: Variant) -> bool:
	if not pool.authoritative or not InventoryTransfer.valid_slot(source, id): return false
	if source == "equipment" and id == "backpack": return _drop_backpack(combat, inventory, equipment)
	var stack := inventory.get_slot(int(id)) if source == "inventory" else equipment.get_slot(str(id))
	if stack == null or stack.item == null or stack.item.id not in NAMES or stack.count < 1 or stack.count > stack.item.max_stack: return false
	var loadout: ActorLoadout = _loadouts.get(combat)
	if loadout != null: loadout.persist_reserve()
	if pool.spawn(stack.item.id, stack.count, combat.actor.global_position, combat.equipment.facing, stack.reserve) == null: return false
	if source == "inventory": inventory.set_slot(int(id), null)
	else: equipment.set_slot(str(id), null)
	return true

func _drop_backpack(combat: PlayerCombat, inventory: PlayerInventory, equipment: CharacterEquipment) -> bool:
	var backpack := equipment.get_slot("backpack")
	if backpack == null or backpack.item == null: return false
	var drop := pool.spawn(backpack.item.id, 1, combat.actor.global_position, combat.equipment.facing, backpack.reserve, inventory.capture())
	if drop == null: return false
	inventory.clear()
	equipment.set_slot("backpack", null)
	return true

func drop_on_death(combat: PlayerCombat) -> void:
	if not pool.authoritative: return
	var loadout: ActorLoadout = _loadouts.get(combat)
	var inventory: PlayerInventory = _inventories.get(combat)
	if loadout == null or inventory == null: return
	var equipment := loadout.equipment
	_drop_backpack(combat, inventory, equipment)
	for slot_name in CharacterEquipment.SLOTS:
		if slot_name == "backpack": continue
		var stack := equipment.get_slot(slot_name)
		if stack == null or stack.item == null or stack.item.id not in NAMES: continue
		if death_roll.is_valid() and float(death_roll.call()) >= DEATH_DROP_CHANCE: continue
		if pool.spawn(stack.item.id, stack.count, combat.actor.global_position, combat.equipment.facing, stack.reserve) != null:
			equipment.set_slot(slot_name, null)
