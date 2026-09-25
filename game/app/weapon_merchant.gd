class_name WeaponMerchant
extends Node

var game: Node3D
var window := WeaponShopWindow.new()
var purchase_handler: Callable
var sale_handler: Callable
var _pending: Array[Dictionary] = []
var _prompt: Label3D
var _ring: MeshInstance3D
var _meshes: Array[MeshInstance3D] = []
var _highlight: StandardMaterial3D

func _ready() -> void:
	window.inventory = game.inventory
	add_child(window)
	window.purchase_requested.connect(_request)
	window.sale_requested.connect(_request_sale)
	window.closed.connect(_closed)
	_prompt = Label3D.new()
	_prompt.text = "[E] Kaji · Gear Shop"
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.position.y = 3.3
	_prompt.font_size = 32
	_prompt.outline_size = 8
	_prompt.modulate = Color("ffdc79")
	_prompt.pixel_size = 0.009
	_prompt.no_depth_test = true
	_prompt.render_priority = 127
	game.world.weapon_merchant.add_child(_prompt)
	_build_highlight()

func nearby(actor: Node3D) -> bool:
	var target: Vector3 = game.world.weapon_merchant.global_position + Vector3(0, 0.6, 0.65)
	if actor.global_position.distance_to(target) > 3.0: return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.6, target, 1)
	return actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _process(_delta: float) -> void:
	var source: LocalPlayerInput = game.shooting_view.local_input
	_prompt.visible = source != null and source.enabled and not source.chat_blocked and game.hud.visible and game.world_items.focused_kind == "merchant" and nearby(game.player)
	_prompt.text = "[%s] Talk to Kaji · Gear Shop" % GamePreferences.binding_text("pickup_weapon", "keyboard")
	_ring.visible = _prompt.visible
	for mesh in _meshes: mesh.material_overlay = _highlight if _prompt.visible else null
	if window.visible and not nearby(game.player): window.close()

func _unhandled_input(event: InputEvent) -> void:
	if not _prompt.visible or event.is_echo() or not event.is_action_pressed("pickup_weapon"): return
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

func _request(id: String) -> void:
	if purchase_handler.is_valid(): purchase_handler.call(id)
	elif _pending.size() < 8: _pending.append({"buy": id})

func _physics_process(_delta: float) -> void:
	for trade in _pending:
		if trade.has("buy"): window.status.text = purchase(game.player, game.inventory, trade.buy)
		else: window.status.text = sell(game.player, game.inventory, trade.slot, trade.id)
	_pending.clear()

func purchase(actor: Node3D, inventory: PlayerInventory, id: String) -> String:
	if not nearby(actor): return "Move closer to Kaji to trade."
	return WeaponTrade.purchase(inventory, id)

func _request_sale(slot: int, id: String) -> void:
	if sale_handler.is_valid(): sale_handler.call(slot, id)
	elif _pending.size() < 8: _pending.append({"slot": slot, "id": id})

func sell(actor: Node3D, inventory: PlayerInventory, slot: int, id: String) -> String:
	if not nearby(actor): return "Move closer to Kaji to trade."
	return WeaponTrade.sell(inventory, slot, id)

func _build_highlight() -> void:
	var npc: Node3D = game.world.weapon_merchant
	for child in npc.get_children():
		if child is MeshInstance3D: _meshes.append(child)
	_highlight = StandardMaterial3D.new()
	_highlight.albedo_color = Color(1.0, 0.85, 0.35, 0.3)
	_highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.64
	torus.outer_radius = 0.73
	_ring.mesh = torus
	_ring.position.y = 0.08
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffdc79")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = material
	npc.add_child(_ring)
	_ring.visible = false
