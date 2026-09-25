class_name CoopInventory
extends Node
## Reliable, bounded transfer intents; only the host mutates actor inventories.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary = {}
var _pending: Dictionary = {}

func _ready() -> void:
	session.game.inventory_window.transfer_handler = request
	session.game.seed_storage.window.transfer_handler = request_storage
	session.game.inventory_window.conversion_handler = request_conversion
	session.game.merchant.purchase_handler = request_purchase
	session.game.merchant.sale_handler = request_sale
	session.room.gameplay_packet.connect(_packet)
	session.game.inventory_window.drop_requested.connect(request_drop)
	session.roster.changed.connect(_members_changed)

func request(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void:
	_sequence += 1
	var data := {"type": "inventory_transfer", "sequence": _sequence,
		"src": src, "src_id": src_id, "dst": dst, "dst_id": dst_id}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func request_storage(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void:
	_sequence += 1
	var data := {"type": "seed_storage_transfer", "sequence": _sequence,
		"src": src, "src_id": src_id, "dst": dst, "dst_id": dst_id}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func request_purchase(id: String) -> void:
	request("shop", id, "shop", 0)

func request_conversion(slot: int, source_id: String) -> String:
	request("refine", slot, "currency", source_id)
	return "Refining request sent to the host."

func request_sale(slot: int, id: String) -> void:
	request("inventory", slot, "shop", id)

func request_drop(source: String, id: Variant) -> void:
	request(source, id, "world", 0)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority and key == session.room.host_key and data.get("type") == "shop_result":
		if data.get("message") is String: session.game.merchant.window.status.text = data.message.left(160)
		return
	if not session.authority and key == session.room.host_key and data.get("type") == "currency_result":
		if data.get("message") is String and session.game.inventory_window._conversion_status != null:
			session.game.inventory_window._conversion_status.text = data.message.left(160)
		return
	if not session.authority or data.get("type") not in ["inventory_transfer", "seed_storage_transfer"]: return
	if not session.roster.party.has(key) or session.opening.active(): return
	if not ExplorationProtocol.sequence(data.get("sequence")): return
	if data.sequence <= _seen.get(key, -1): return
	var storage: bool = data.get("type") == "seed_storage_transfer"
	if storage:
		if not ChestTransfer.valid_slot(data.get("src"), data.get("src_id")) or not ChestTransfer.valid_slot(data.get("dst"), data.get("dst_id")): return
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
	for key: String in _pending:
		if not session.roster.party.has(key) or session.opening.active(): continue
		var member: CoopActor = session.roster.party[key]
		for data: Dictionary in _pending[key]:
			if data.type == "seed_storage_transfer":
				session.game.seed_storage.transfer(member.actor, member.inventory, data.src, data.src_id, data.dst, data.dst_id)
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

func _members_changed() -> void:
	for key: String in _seen.keys():
		if not session.roster.party.has(key):
			_seen.erase(key)
			_pending.erase(key)
