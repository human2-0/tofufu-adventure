class_name QuestGiver
extends Node
## App coordinator connecting Mayor Mame, quest progression, encounters and rewards.

var game: Node3D
var quest := QuestState.new()
var window := QuestWindow.new()

var _prompt: Label3D
var _ring: MeshInstance3D
var _meshes: Array[MeshInstance3D] = []
var _highlight: StandardMaterial3D

func _ready() -> void:
	add_child(window)
	window.quest_accepted.connect(_on_quest_accepted)
	window.reward_claimed.connect(_on_reward_claimed)
	window.closed.connect(_on_window_closed)
	quest.changed.connect(_refresh_window)
	if game.world.quest_npc != null:
		_setup_npc_interaction()
	if game.encounters != null:
		game.encounters.mob_defeated.connect(_on_mob_defeated)

func _setup_npc_interaction() -> void:
	var npc: Node3D = game.world.quest_npc
	_prompt = Label3D.new()
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.position.y = 3.0
	_prompt.font_size = 32
	_prompt.outline_size = 8
	_prompt.modulate = Color("ffdc79")
	_prompt.pixel_size = 0.009
	npc.add_child(_prompt)
	_build_highlight(npc)

func nearby(actor: Node3D) -> bool:
	if game.world.quest_npc == null or actor == null:
		return false
	var target: Vector3 = game.world.quest_npc.global_position + Vector3(0, 0.6, 0.65)
	if actor.global_position.distance_to(target) > 3.0:
		return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.6, target, 1)
	return actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _process(_delta: float) -> void:
	if _prompt == null:
		return
	var source: LocalPlayerInput = game.shooting_view.local_input
	var is_nearby := nearby(game.player)
	_prompt.visible = source != null and source.enabled and not source.chat_blocked and game.hud.visible and is_nearby
	if _prompt.visible:
		var key := GamePreferences.binding_text("pickup_weapon", "keyboard")
		if quest.status == QuestState.Status.COMPLETED:
			_prompt.text = "[%s] Mayor Mame · Claim Reward" % key
		else:
			_prompt.text = "[%s] Talk to Mayor Mame · Quests" % key
	_ring.visible = _prompt.visible
	for mesh in _meshes:
		mesh.material_overlay = _highlight if _prompt.visible else null
	if window.visible and not is_nearby:
		window.close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if window.visible and (event.is_action_pressed("toggle_inventory") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("pickup_weapon")):
		window.close()
		get_viewport().set_input_as_handled()
		return
	if not _prompt.visible or not event.is_action_pressed("pickup_weapon"):
		return
	open_dialog()
	get_viewport().set_input_as_handled()

func open_dialog() -> void:
	_refresh_window()
	window.open()
	game.shooting_view.local_input.enabled = false
	game.chat.set_menu_open(true)
	game.combat.reset()
	game.player.motor.cancel_jump()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_window_closed() -> void:
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)

func _refresh_window() -> void:
	window.present({
		"status": quest.status,
		"current_count": quest.current_count,
		"target_count": quest.target_count
	})

func _on_quest_accepted() -> void:
	quest.start()
	game.hud.announce("Quest Accepted: Cull 50 Slimes")
	_refresh_window()

func _on_mob_defeated(_at: Vector3) -> void:
	if quest.status != QuestState.Status.IN_PROGRESS:
		return
	quest.record_kill()
	if quest.status == QuestState.Status.COMPLETED:
		game.hud.announce("Quest Complete! Return to Mayor Mame.")
	else:
		game.hud.announce("Quest: %d / %d Slimes" % [quest.current_count, quest.target_count])

func _on_reward_claimed() -> void:
	if not quest.claim_reward():
		return
	game.inventory.coins += quest.reward_coins
	var rare_item := InventoryItem.create_rare_soybean()
	var leftover: int = game.inventory.add_item(rare_item, 1)
	if leftover > 0:
		game.inventory.pending_items.append(ItemStack.new(rare_item, 1))
		game.hud.announce("+100 Coins · Rare Soybean saved to pending items!")
	else:
		game.hud.announce("+100 Coins · Obtained Rare Soybean!")
	CombatEffects.burst(game, game.player.global_position, "+100 COINS", Color("ffd666"))
	_refresh_window()

func _build_highlight(npc: Node3D) -> void:
	for child in npc.get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
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
