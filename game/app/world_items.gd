class_name WorldItems
extends Node
## Wires shared world drops to actor equipment, local focus, and inventory grants.

const NAMES := {"knife": "Knife", "soy_gun": "Soybean gun", "sotjet": "Sotjet", "soybean": "Soya beans"}
var game: Node3D
var pool := WorldItemPool.new()
var focused_id: int = 0
var _inventories: Dictionary = {}
var _loadouts: Dictionary = {}
var _bag_drops: Array = []

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
	var id := "sotjet" if combat.sotjet.selected else ("soy_gun" if combat.gun.selected else ("knife" if gear.knife_selected else ""))
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

func _pickup(id: int, combat: PlayerCombat) -> bool:
	if not pool.authoritative: return false
	if id < 0: id = pool.focused(combat.actor.global_position, combat.equipment.facing)
	var drop: WorldItemDrop = pool.drops.get(id)
	if drop == null or not pool.reachable(drop, combat.actor.global_position): return false
	if drop.item_id == "soybean":
		var inventory: PlayerInventory = _inventories.get(combat)
		if inventory == null: return false
		var remaining := inventory.add_item(InventoryItem.create_soybean(), drop.count)
		if remaining == drop.count: return false
		drop.count = remaining
		if remaining == 0: pool.remove(id)
		return true
	var loadout: ActorLoadout = _loadouts.get(combat)
	if loadout == null: return false
	var stack := ItemStack.new(InventoryItem.weapon(drop.item_id), 1)
	stack.reserve = drop.reserve
	if not loadout.receive(stack): return false
	pool.remove(id)
	return true

func _owns(combat: PlayerCombat, id: String) -> bool:
	if id == "knife": return combat.equipment.knife_owned
	if id == "soy_gun": return combat.equipment.gun_owned
	return combat.equipment.sotjet_owned

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

func _process(_delta: float) -> void:
	var previous := focused_id
	focused_id = 0
	var source: LocalPlayerInput = game.shooting_view.local_input if game.shooting_view != null else null
	if source != null and source.enabled and not source.chat_blocked and game.hud.visible and not get_tree().paused:
		focused_id = pool.focused(game.player.global_position, source.focus_direction(), source.focus_point)
	if source != null: source.pickup_target = focused_id
	if pool.drops.has(previous): pool.drops[previous].set_focus(false, "")
	if not pool.drops.has(focused_id): return
	var drop := pool.drops[focused_id]
	var action := "Pick up"
	var binding := GamePreferences.binding_text("pickup_weapon", "keyboard")
	var title: String = NAMES.get(drop.item_id, drop.item_id)
	if drop.count > 1: title += " ×%d" % drop.count
	if drop.item_id == "soybean" and not game.inventory.has_space_for(InventoryItem.create_soybean(), 1):
		drop.set_focus(true, "Bag full · " + title)
	else: drop.set_focus(true, "[%s] %s %s" % [binding, action, title])

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
	var stack := inventory.get_slot(int(id)) if source == "inventory" else equipment.get_slot(str(id))
	if stack == null or stack.item == null or stack.item.id not in NAMES or stack.count < 1 or stack.count > stack.item.max_stack: return false
	var loadout: ActorLoadout = _loadouts.get(combat)
	if loadout != null: loadout.persist_reserve()
	if pool.spawn(stack.item.id, stack.count, combat.actor.global_position, combat.equipment.facing, stack.reserve) == null: return false
	if source == "inventory": inventory.set_slot(int(id), null)
	else: equipment.set_slot(str(id), null)
	return true
