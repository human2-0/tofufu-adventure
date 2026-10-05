class_name CoopInventory
extends Node
## Reliable, bounded transfer intents; only the host mutates actor inventories.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary = {}
var _pending: Dictionary = {}

func _ready() -> void:
	process_physics_priority = session.process_physics_priority + 1
	session.game.inventory_window.transfer_handler = request
	session.game.inventory_window.quick_transfer_handler = request_storage_quick
	session.game.seed_storage.window.transfer_handler = request_storage
	session.game.seed_storage.window.quick_transfer_handler = request_storage_quick
	session.game.inventory_window.conversion_handler = request_conversion
	session.game.inventory_window.consume_handler = request_consume
	session.game.merchant.purchase_handler = request_purchase
	session.game.merchant.sale_handler = request_sale
	session.room.gameplay_packet.connect(_packet)
	session.game.inventory_window.drop_requested.connect(request_drop)
	session.roster.changed.connect(_members_changed)
	session.duel.entry_started.connect(discard_pending)

func request(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void:
	_sequence += 1
	var data := {"type": "inventory_transfer", "sequence": _sequence,
		"src": src, "src_id": src_id, "dst": dst, "dst_id": dst_id}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func request_storage(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void:
	_sequence += 1
	var data := {"type": "seed_storage_transfer", "sequence": _sequence, "bay": session.game.seed_storage._open_bay,
		"src": src, "src_id": src_id, "dst": dst, "dst_id": dst_id}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func request_storage_quick(src: String, src_id: Variant) -> String:
	if not session.game.seed_storage.nearby(session.game.player): return "Move closer to the Seed Bank to use its depot."
	_sequence += 1
	var data := {"type": "seed_storage_quick_transfer", "sequence": _sequence, "bay": session.game.seed_storage._open_bay if session.game.seed_storage.window.visible else session.game.seed_storage.bay_for(session.game.player), "src": src, "src_id": src_id}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)
	return "Storage transfer requested."

func request_purchase(id: String) -> void:
	request("shop", id, "shop", 0)

func request_conversion(slot: int, source_id: String) -> String:
	request("refine", slot, "currency", source_id)
	return "Refining request sent to the host."

func request_sale(slot: int, id: String) -> void:
	request("inventory", slot, "shop", id)

func request_consume(slot: int) -> bool:
	_sequence += 1
	var data := {"type": "inventory_consume", "sequence": _sequence, "slot": slot}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)
	return true

func request_drop(source: String, id: Variant) -> void:
	request(source, id, "world", 0)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority and key == session.room.host_key and data.get("type") == "shop_result":
		if data.get("message") is String: session.game.merchant.window.status.text = data.message.left(160)
		return
	if not session.authority and key == session.room.host_key and data.get("type") == "storage_result":
		if data.get("message") is String: session.game.seed_storage.window._status.text = data.message.left(160)
		return
	if not session.authority and key == session.room.host_key and data.get("type") == "currency_result":
		if data.get("message") is String and session.game.inventory_window._conversion_status != null:
			session.game.inventory_window._conversion_status.text = data.message.left(160)
		return
	if not session.authority or data.get("type") not in ["inventory_transfer", "seed_storage_transfer", "seed_storage_quick_transfer", "inventory_consume"]: return
	if not session.roster.party.has(key) or session.opening.active(): return
	if session.duel.is_participant(key): return
	if not ExplorationProtocol.sequence(data.get("sequence")): return
	if data.sequence <= _seen.get(key, -1): return
	var storage: bool = data.get("type") == "seed_storage_transfer"
	var quick_storage: bool = data.get("type") == "seed_storage_quick_transfer"
	if storage or quick_storage:
		if not ExplorationProtocol.sequence(data.get("bay")) or data.bay >= 20: return
	if data.get("type") == "inventory_consume":
		if not InventoryTransfer.valid_slot("inventory", data.get("slot")): return
	elif storage:
		if not ChestTransfer.valid_slot(data.get("src"), data.get("src_id")) or not ChestTransfer.valid_slot(data.get("dst"), data.get("dst_id")): return
	elif quick_storage:
		if not ChestTransfer.valid_slot(data.get("src"), data.get("src_id")): return
	else:
		var refining: bool = data.get("src") == "refine" and data.get("dst") == "currency"
		var shopping: bool = data.get("src") == "shop" and data.get("dst") == "shop"
		if refining:
			if not InventoryTransfer.valid_slot("inventory", data.get("src_id")): return
			if data.get("dst_id") not in CurrencyExchange.NEXT_TIER: return
		elif shopping:
			if data.get("src_id") not in WeaponTrade.BUYABLE_IDS: return
		else:
			if not InventoryTransfer.valid_slot(data.get("src"), data.get("src_id")): return
			if data.get("dst") == "shop":
				if data.get("src") != "inventory" or not data.get("dst_id") is String or data.dst_id.length() > 64: return
			elif data.get("dst") != "world" and not InventoryTransfer.valid_slot(data.get("dst"), data.get("dst_id")): return
	_seen[key] = int(data.sequence)
	# At most sixteen transfers per actor between physics ticks.
	if not _pending.has(key): _pending[key] = []
	if _pending[key].size() < 16: _pending[key].append(data.duplicate())

func _physics_process(_delta: float) -> void:
	for key: String in _pending.keys():
		if not session.roster.party.has(key) or session.opening.active() or session.duel.is_participant(key):
			_pending.erase(key)
			continue
		var member: CoopActor = session.roster.party[key]
		for data: Dictionary in _pending[key]:
			if data.type == "seed_storage_transfer":
				var stored: bool = session.game.seed_storage.transfer(member.actor, member.inventory, data.src, data.src_id, data.dst, data.dst_id, int(data.bay))
				_storage_result(key, "Transferred safely." if stored else "Transfer refused: check chest ownership, distance and space.")
				continue
			if data.type == "seed_storage_quick_transfer":
				_storage_result(key, session.game.seed_storage.quick_transfer(member.actor, member.inventory, data.src, data.src_id, int(data.bay)))
				continue
			if data.type == "inventory_consume":
				member.healing.consume_from_bag(member.inventory, int(data.get("slot", -1)))
				continue
			if data.src == "refine":
				var refinement: String = CurrencyExchange.convert(member.inventory, int(data.src_id), str(data.dst_id))
				if key == session.room.local_key: session.game.inventory_window._conversion_status.text = refinement
				else: session.room.send_game(key, {"type": "currency_result", "message": refinement})
				continue
			if data.dst == "shop":
				var message: String
				if data.src == "shop": message = session.game.merchant.purchase(member.actor, member.inventory, data.src_id)
				else: message = session.game.merchant.sell(member.actor, member.inventory, int(data.src_id), data.dst_id)
				if key == session.room.local_key: session.game.merchant.window.status.text = message
				else: session.room.send_game(key, {"type": "shop_result", "message": message})
				continue
			if data.dst == "world":
				session.game.world_items.drop_stack(member.combat, member.inventory, member.character_equipment, data.src, data.src_id)
				continue
			InventoryTransfer.apply(member.inventory, member.character_equipment,
				data.src, data.src_id, data.dst, data.dst_id)
	_pending.clear()

func discard_pending(participants: Array[String]) -> void:
	for key in participants:
		_pending.erase(key)

func _members_changed() -> void:
	for key: String in _seen.keys():
		if not session.roster.party.has(key):
			_seen.erase(key)
			_pending.erase(key)

func _storage_result(key: String, message: String) -> void:
	if key == session.room.local_key: session.game.seed_storage.window._status.text = message
	else: session.room.send_game(key, {"type": "storage_result", "message": message})
