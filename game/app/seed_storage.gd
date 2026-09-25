class_name SeedStorage
extends Node
## App composition for entering the seed bank and safely moving bag stacks into its chest wall.

var game: Node3D
var chest := ChestInventory.new()
var window := ChestWindow.new()
var free_satchel_claimed: bool = false
var _prompt: Label3D

func _ready() -> void:
	window.inventory = game.inventory
	window.chest = chest
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

func nearby(actor: Node3D) -> bool:
	if actor == null or game.world.seed_bank == null: return false
	var target: Vector3 = game.world.seed_bank.global_position + Vector3(0, 0.85, 1.5)
	if actor.global_position.distance_to(target) > 2.25: return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.6, target, 1, [actor.get_rid()])
	return actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func transfer(actor: Node3D, inventory: PlayerInventory, src: String, src_id: Variant, dst: String, dst_id: Variant) -> bool:
	if not nearby(actor): return false
	return ChestTransfer.apply(inventory, chest, src, src_id, dst, dst_id)

func _place_free_satchel() -> void:
	if not is_inside_tree() or not is_instance_valid(game) or game.is_queued_for_deletion(): return
	if not game.world_items.pool.is_inside_tree(): return
	if free_satchel_claimed or not game.world_items.pool.authoritative: return
	for drop: WorldItemDrop in game.world_items.pool.drops.values():
		if drop.item_id == "seed_satchel": return
	var bank: Node3D = game.world.seed_bank
	if bank == null or not bank.is_inside_tree(): return
	var at: Vector3 = game.world.ground_point(bank.global_position.x + 1.55, bank.global_position.z + 4.65, 0.08)
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
		_prompt.text = "[%s] Seed chests · 24 safe slots" % GamePreferences.binding_text("pickup_weapon", "keyboard")
	if window.visible and not nearby(game.player): window.close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon"): return
	if window.visible:
		window.close()
		get_viewport().set_input_as_handled()
		return
	if _prompt == null or not _prompt.visible: return
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
