class_name WorldInteractionFocus
extends RefCounted
## Local target scoring and prompts; does not transfer inventory or grant loot.

static func process(items: WorldItems, _delta: float) -> void:
	var previous := items.focused_id
	items.focused_id = 0
	items.focused_kind = ""
	items.focused_plot = -1
	var source: LocalPlayerInput = items.game.shooting_view.local_input if items.game.shooting_view != null else null
	if source != null and source.enabled and not source.chat_blocked and items.game.hud.visible and not items.get_tree().paused:
		select_focus(items, source)
	if source != null:
		source.pickup_target = items.focused_id
		source.castle_action = items.focused_plot if items.focused_kind == "castle" else -1
		source.castle_revision = items.game.castle_adventure.state.revision if items.game.castle_adventure != null else 0
	if items.pool.drops.has(previous): items.pool.drops[previous].set_focus(false, "")
	if not items.pool.drops.has(items.focused_id): return
	var drop := items.pool.drops[items.focused_id]
	var action := "Pick up"
	var binding := GamePreferences.binding_text("pickup_weapon", "keyboard")
	var title: String = items.NAMES.get(drop.item_id, drop.item_id)
	if drop.count > 1: title += " ×%d" % drop.count
	var item := InventoryItem.from_id(drop.item_id)
	if item != null and item.category != "backpack" and not items.game.inventory.has_space_for(item, 1):
		drop.set_focus(true, "Bag full · " + title)
	else: drop.set_focus(true, "[%s] %s %s" % [binding, action, title])

static func select_focus(items: WorldItems, source: LocalPlayerInput, pointer: Vector2 = Vector2.INF) -> void:
	var origin: Vector3 = items.game.player.global_position
	var camera := items.get_viewport().get_camera_3d()
	if not pointer.is_finite():
		pointer = items.get_viewport().get_visible_rect().size * 0.5 if source.shoulder_view else items.get_viewport().get_mouse_position()
	var best := INF
	for id: int in items.pool.drops:
		var drop: WorldItemDrop = items.pool.drops[id]
		if not items.pool.reachable(drop, origin) or not BarnDisplay.can_pickup(items, drop, items.game.player): continue
		var at := drop.global_position if drop.display_bay >= 0 else drop.global_position + Vector3.UP * 0.45
		var score := items._focus_score(at, origin, source, camera, pointer)
		if score < best:
			best = score
			items.focused_kind = "drop"
			items.focused_id = id
	if items.game.quest_giver != null and items.game.quest_giver.nearby(items.game.player):
		best = consider(items, "quest", items.game.world.quest_npc.global_position + Vector3(0, 1.5, 0.65), origin, source, camera, pointer, best)
	if items.game.merchant != null and items.game.merchant.nearby(items.game.player):
		best = consider(items, "merchant", items.game.merchant.focus_position(items.game.player), origin, source, camera, pointer, best)
	if items.game.seed_storage != null and items.game.seed_storage.nearby(items.game.player):
		best = consider(items, "storage", items.game.seed_storage.focus_position(items.game.player), origin, source, camera, pointer, best)
	if items.game.parrot_travel != null and items.game.parrot_travel.available(items.game.player):
		var perches: ParrotPerches = items.game.parrot_travel.perches
		var index := perches.nearest(origin)
		var at: Vector3 = items.game.player.get_parent().to_global(items.game.player.parrot_rest) if index < 0 else perches.stations[index].global_position
		best = consider(items, "parrot", at + Vector3.UP, origin, source, camera, pointer, best)
	if items.game.farming != null and items.game.farming.available():
		for index in items.game.farming.plots.size():
			var plot: SoybeanPlot = items.game.farming.plots[index]
			if not items.game.farming.reachable(items.game.player, plot): continue
			var score := items._focus_score(plot.global_position + Vector3.UP * 0.5, origin, source, camera, pointer)
			if score < best:
				best = score
				items.focused_kind = "plot"
				items.focused_id = 0
				items.focused_plot = index
	if items.game.apple_harvest != null and items.game.apple_harvest.available():
		var tree: AppleTree = items.game.apple_harvest.nearest(origin)
		if tree != null and (tree.can_harvest() or items.focused_kind != "drop"):
			var score := items._focus_score(tree.global_position + Vector3.UP * 1.5, origin, source, camera, pointer)
			if score < best:
				best = score
				items.focused_kind = "apple_tree"
				items.focused_id = 0
				items.focused_plot = -1

	if items.game.castle_adventure != null:
		var castle: CastleAdventure = items.game.castle_adventure
		for action in 25:
			if not castle.reachable(items.game.player, action): continue
			var score := items._focus_score(castle.focus_position(action), origin, source, camera, pointer)
			if score < best:
				best = score
				items.focused_kind = "castle"
				items.focused_id = 0
				items.focused_plot = action

static func consider(items: WorldItems, kind: String, at: Vector3, origin: Vector3, source: LocalPlayerInput, camera: Camera3D, pointer: Vector2, best: float) -> float:
	var score := items._focus_score(at, origin, source, camera, pointer)
	if score < best:
		items.focused_kind = kind
		items.focused_id = 0
		items.focused_plot = -1
		return score
	return best

static func focus_score(items: WorldItems, at: Vector3, origin: Vector3, source: LocalPlayerInput, camera: Camera3D, pointer: Vector2) -> float:
	var offset := Vector2(at.x - origin.x, at.z - origin.z)
	var distance := offset.length()
	if source.pointer_focus() and camera != null:
		if camera.is_position_behind(at): return INF
		return camera.unproject_position(at).distance_to(pointer) / items.get_viewport().get_visible_rect().size.y + distance * 0.01
	var alignment := source.focus_direction().normalized().dot(offset.normalized()) if distance > 0.01 else 1.0
	return (1.0 - alignment) * 2.0 + distance * 0.3
