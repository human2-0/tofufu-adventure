class_name BattlePackUI
extends Node
## Local modal controls send validated intents; even the host never mutates via UI.
var game: BattleRoyaleGame
var bag: BattleInventoryWindow
var panel: BattleLootPanel
var page: String = ""
var _stamp: String = ""
var _last_request: int = 0
var _items: Array[InventoryItem] = []

func _ready() -> void:
	for kind in BattlePackWire.ITEMS.size(): _items.append(BattleItems.make(kind + 1))
	var fighter := game.combat.fighters[game.local_slot]
	bag = BattleInventoryWindow.new()
	bag.inventory = fighter.loadout.inventory
	bag.equipment = fighter.loadout.equipment
	bag.transfer_handler = _transfer
	bag.consume_handler = _consume
	bag.quick_transfer_handler = _quick
	game.add_child(bag)
	bag.drop_requested.connect(_drop)
	bag.character_requested.connect(show_stats)
	panel = BattleLootPanel.new()
	game.add_child(panel)
	panel.close_requested.connect(close)
	panel.backpack_requested.connect(show_bag)
	panel.take_requested.connect(func(id: int) -> void: _send(1, [id]))

func blocked() -> bool:
	return bag.visible or panel.visible

func close() -> void:
	bag.close()
	panel.hide()
	page = ""
	_stamp = ""

func show_bag() -> void:
	close()
	bag.open()

func show_stats() -> void:
	close()
	page = "stats"
	update()

func show_loot() -> void:
	close()
	page = "loot"
	for row: Array in game.match_state.chests:
		if row[4] == 0 and game.pack.reachable(game.local_slot, Vector3(row[1], row[2], row[3]), int(row[0])):
			_send(0, [int(row[0])])
			break
	update()

func _input(event: InputEvent) -> void:
	if not blocked(): return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_inventory") or event.is_action_pressed("toggle_character"):
		if not event.is_echo():
			if event.is_action_pressed("toggle_inventory") and not bag.visible: show_bag()
			elif event.is_action_pressed("toggle_character") and page != "stats": show_stats()
			else: close()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not game.composed or not game.playing or game.deployment.active() or game.hud.exit_panel.visible: return
	if game.match_state.rows[game.local_slot][8] <= 0 or game.match_state.winner != -2: return
	if event.is_action_pressed("toggle_inventory"): show_bag()
	elif event.is_action_pressed("toggle_character"): show_stats()
	elif event.is_action_pressed("pickup_weapon"): show_loot()
	else: return
	get_viewport().set_input_as_handled()

func update() -> void:
	if not game.composed: return
	if game.match_state.rows[game.local_slot][8] <= 0:
		close()
		return
	if game.pack.requests.replies.has(_last_request):
		var ok: bool = game.pack.requests.replies[_last_request]
		game.pack.requests.replies.erase(_last_request)
		var message := tr("Item action complete.") if ok else tr("Could not move this item. Check your space, distance and current equipment.")
		panel.note.text = message
		bag._conversion_status.text = message
	if page == "stats":
		var text := BattlePackStats.text(game)
		if text != _stamp:
			_stamp = text
			panel.display(tr("Match stats"), tr("Your equipment changes these stats for this match."), [{"label": text}])
	elif page == "loot": _loot()

func _loot() -> void:
	var rows: Array = []
	var tokens: Array = [TranslationServer.get_locale(), game.pack.revisions[game.local_slot]]
	var inventory := game.combat.fighters[game.local_slot].loadout.inventory
	for drop: Array in game.match_state.drops:
		if drop[5] <= 0 or not game.pack.reachable(game.local_slot, Vector3(drop[1], drop[2], drop[3])): continue
		var item := _items[int(drop[4]) - 1]
		var label := tr(item.name) + " ×%d" % int(drop[5])
		if item.category in CharacterEquipment.APPAREL_SLOTS: label += " · " + tr("Durability %.0f/50") % (float(drop[6]) * 0.5)
		rows.append({"id": drop[0], "label": label, "icon": item.icon, "color": BattleRarity.COLORS[BattleRarity.grade(int(drop[4]))], "enabled": inventory.has_space_for(item, int(drop[5]))})
		tokens.append(drop)
	var stamp := JSON.stringify(tokens)
	if stamp == _stamp: return
	_stamp = stamp
	panel.display(tr("Nearby loot"), tr("Choose what to carry. All chests share the same item chances.") if not rows.is_empty() else tr("No loose items in reach. Move closer to a chest or a dropped item."), rows)

func _send(action: int, args: Array) -> void:
	game.pack.requests.request(action, args)
	_last_request = game.pack.requests.sequence
	panel.note.text = tr("Checking item…")

func _transfer(source: String, from: Variant, target: String, to: Variant) -> void:
	_send(2, [_source(source), _index(source, from), _source(target), _index(target, to)])

func _consume(index: int) -> bool:
	_send(3, [0, index])
	return true

func _drop(source: String, index: Variant) -> void:
	_send(4, [_source(source), _index(source, index)])

func _quick(source: String, index: Variant) -> String:
	if source != "inventory": return ""
	var stack := bag.inventory.get_slot(int(index))
	if stack == null: return ""
	var destination := stack.item.category
	if destination == "combat": destination = "combat_1" if BattleItems.weapon_kind(stack) in BattleGear.MELEE else "combat_2"
	if destination == "support":
		for name in ["support_1", "support_2", "support_3", "support_4"]:
			if bag.equipment.get_slot(name) == null: destination = name; break
	if destination in CharacterEquipment.SLOTS: _transfer("inventory", index, "equipment", destination)
	return tr("Checking item…")

func _source(value: String) -> int:
	return 0 if value == "inventory" else 1

func _index(source: String, value: Variant) -> int:
	return int(value) if source == "inventory" else CharacterEquipment.SLOTS.find(str(value))
