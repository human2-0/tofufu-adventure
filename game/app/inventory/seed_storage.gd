class_name SeedStorage
extends Node
## App composition for personal barn bays, frontal reach and safe inventory transfers.

var game: Node3D
var barn := BarnChests.new()
var chest: ChestInventory = barn.banks[0]
var _open_bay: int = -1
var window := ChestWindow.new()
var free_satchel_claimed: bool = false
var _prompt: Label3D

func _ready() -> void:
	window.inventory = game.inventory
	window.chest = chest
	window.transfer_handler = func(src: String, src_id: Variant, dst: String, dst_id: Variant) -> void: transfer(game.player, game.inventory, src, src_id, dst, dst_id, _open_bay)
	window.quick_transfer_handler = func(source: String, id: Variant) -> String: return quick_transfer(game.player, game.inventory, source, id, _open_bay)
	window.closed.connect(_closed)
	add_child(window)
	game.world_items.backpack_claimed.connect(_on_backpack_claimed)
	call_deferred("_place_free_satchel")
	if game.world.seed_bank == null: return
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.position = Vector3(0, 2.25, 1.55)
	_prompt.font_size = 32
	_prompt.outline_size = 8
	_prompt.modulate = Color("ffdc79")
	_prompt.pixel_size = 0.009
	_prompt.no_depth_test = true
	_prompt.render_priority = 127
	game.world.seed_bank.add_child(_prompt)

func bay_for(actor: Node3D) -> int:
	if actor == null or game.world.seed_bank == null: return -1
	var barn_node: Node3D = game.world.seed_bank
	var local: Vector3 = barn_node.to_local(actor.global_position)
	var best := 2.15
	var selected := -1
	for index in MeadowBarn.BAY_COUNT:
		var target := MeadowBarn.table_position(index) + MeadowBarn.front(index) * 0.7
		var distance := Vector2(local.x - target.x, local.z - target.z).length()
		if distance >= best or (local - MeadowBarn.table_position(index)).dot(MeadowBarn.front(index)) < 0.15: continue
		var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.7, barn_node.to_global(target), 1)
		if not actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		best = distance
		selected = index
	return selected

func nearby(actor: Node3D) -> bool:
	return bay_for(actor) >= 0

func focus_position(actor: Node3D) -> Vector3:
	var index := bay_for(actor)
	# Aim at the chest lid, separate from the item sitting on its display desk.
	return game.world.seed_bank.to_global(MeadowBarn.bay_position(index) + Vector3.UP * 0.88) if index >= 0 else Vector3.INF

func transfer(actor: Node3D, inventory: PlayerInventory, src: String, src_id: Variant, dst: String, dst_id: Variant, expected_bay: int = -1) -> bool:
	var index := bay_for(actor)
	if index < 0 or (expected_bay >= 0 and index != expected_bay) or not barn.permitted(index, actor): return false
	if not ChestTransfer.apply(inventory, barn.banks[index], src, src_id, dst, dst_id): return false
	barn.permitted(index, actor, true)
	return true

func quick_transfer(actor: Node3D, inventory: PlayerInventory, source: String, id: Variant, expected_bay: int = -1) -> String:
	var index := bay_for(actor)
	if index < 0 or (expected_bay >= 0 and index != expected_bay): return "Move to the front of a chest bay."
	if not barn.permitted(index, actor): return "This chest belongs to another Fufu."
	if not ChestTransfer.quick_move(inventory, barn.banks[index], source, id): return "No room in the other inventory."
	barn.permitted(index, actor, true)
	return "Stored in your personal chest." if source == "inventory" else "Moved to your bag."

func _place_free_satchel() -> void:
	if not is_inside_tree() or not is_instance_valid(game) or game.is_queued_for_deletion(): return
	if not game.world_items.pool.is_inside_tree(): return
	if free_satchel_claimed or not game.world_items.pool.authoritative: return
	for drop: WorldItemDrop in game.world_items.pool.drops.values():
		if drop.item_id == "seed_satchel": return
	var bank: Node3D = game.world.seed_bank
	if bank == null or not bank.is_inside_tree(): return
	var at: Vector3 = game.world.ground_point(bank.global_position.x + 1.55, bank.global_position.z + 15.5, 0.08)
	game.world_items.pool.spawn("seed_satchel", 1, at, Vector2(0.2, 1.0))

func _on_backpack_claimed(item_id: String) -> void:
	if item_id == "seed_satchel": free_satchel_claimed = true

func reset_for_death() -> void:
	free_satchel_claimed = false
	_place_free_satchel()

func _process(_delta: float) -> void:
	if _prompt == null: return
	var source: LocalPlayerInput = game.shooting_view.local_input
	_prompt.visible = source != null and source.enabled and not source.chat_blocked and game.hud.visible and game.world_items.focused_kind == "storage" and nearby(game.player)
	if _prompt.visible:
		var index := bay_for(game.player)
		_prompt.global_position = focus_position(game.player) + Vector3.UP
		_prompt.text = "[%s] Chest %02d · %s" % [GamePreferences.binding_text("pickup_weapon", "keyboard"), index + 1, "Personal storage" if barn.permitted(index, game.player) else "Owned by another Fufu"]
	if window.visible and bay_for(game.player) != _open_bay: window.close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon"): return
	if window.visible:
		window.close()
		get_viewport().set_input_as_handled()
		return
	if _prompt == null or not _prompt.visible or game.world_items.focused_kind != "storage": return
	_open_bay = bay_for(game.player)
	if not barn.permitted(_open_bay, game.player): return
	chest = barn.banks[_open_bay]
	window.chest = chest
	window.open()
	game.shooting_view.local_input.enabled = false
	game.chat.set_menu_open(true)
	game.combat.reset()
	game.player.motor.cancel_jump()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().set_input_as_handled()

func _closed() -> void:
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)
