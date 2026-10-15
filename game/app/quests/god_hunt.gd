class_name GodHunt
extends Node
## Godfufu's first per-character hunt, paid exactly once by the authority.

var game: AdventureGame
var request_action: Callable
var window := GodHuntWindow.new()
var prompt: Label3D

func _ready() -> void:
	add_child(window)
	window.action_requested.connect(_action)
	window.closed.connect(_closed)
	game.encounters.angel_defeated.connect(_kill)
	prompt = MobLabels.make(game.world.cloud_realm.godfufu, "", 28, 0.009, Color("ffdc79"), 3.8)

func nearby(actor: Node3D) -> bool:
	var npc := game.world.cloud_realm.godfufu
	if actor == null or actor.global_position.distance_to(npc.global_position) > 3.5: return false
	var body := npc.get_child(1) as StaticBody3D
	var exclusions: Array[RID] = []
	if body != null: exclusions.append(body.get_rid())
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, npc.global_position + Vector3.UP, 1, exclusions)
	return actor.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _process(_delta: float) -> void:
	var input := game.shooting_view.local_input
	prompt.visible = input != null and game.hud.visible and input.enabled and not input.chat_blocked and not game.player.transport_active and nearby(game.player) and game.world_items.focused_kind == "god_quest"
	prompt.text = "[%s] Godfufu · Fallen Groatguard (%d / 200)" % [GamePreferences.binding_text("pickup_weapon", "keyboard"), game.quest_giver.quest.god_count]
	if window.visible: window.present(game.quest_giver.quest.god_status, game.quest_giver.quest.god_count)
	if window.visible and not nearby(game.player): window.close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo(): return
	if window.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pickup_weapon") or event.is_action_pressed("toggle_inventory")):
		window.close()
		get_viewport().set_input_as_handled()
	elif prompt.visible and event.is_action_pressed("pickup_weapon"):
		window.visible = true
		game.shooting_view.local_input.enabled = false
		game.chat.set_menu_open(true)
		game.combat.reset()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()

func _closed() -> void:
	game.shooting_view.local_input.enabled = true
	game.chat.set_menu_open(false)

func _kill(_at: Vector3) -> void:
	if game.quest_giver.quest.god_status != QuestState.Status.IN_PROGRESS: return
	game.quest_giver.quest.record_angel_kill()
	if game.quest_giver.quest.god_status == QuestState.Status.COMPLETED:
		game.hud.announce("Fallen Groatguard complete · Return to Godfufu")

func _action(action: String) -> void:
	if request_action.is_valid():
		request_action.call(action, false, true)
		return
	if not nearby(game.player): return
	if action == "accept": game.quest_giver.quest.start_god()
	elif game.quest_giver.quest.claim_god():
		var item := InventoryItem.currency("golden_tofu_chunk")
		var left := game.inventory.add_item(item, 10)
		if left > 0: game.inventory.pending_items.append(ItemStack.new(item, left))
		game.progression.progress.award_experience(50000)
		game.hud.announce("Godfufu · +50,000 EXP · +10 Golden Tofufu Chunks")
