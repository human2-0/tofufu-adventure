class_name AppleHarvest
extends Node3D
## Manages player collection of apples from orchard trees in the meadow.

var game: Node3D
var trees: Array[AppleTree] = []
var focused_tree: AppleTree = null
var authoritative: bool = true
var request_harvest: Callable
var _pending: AppleTree

func setup(p_game: Node3D) -> void:
	game = p_game
	trees = game.world.apple_trees
	for tree in trees:
		tree.apples_felled.connect(_apples_fell.bind(tree))

func available() -> bool:
	var source: LocalPlayerInput = game.shooting_view.local_input if game.shooting_view != null else null
	return game.hud.visible and source != null and source.enabled and not source.chat_blocked and not game.inventory_window.visible and not game.map.expanded

func nearest(origin: Vector3 = Vector3.ZERO) -> AppleTree:
	if not available(): return null
	if origin == Vector3.ZERO and game.player != null:
		origin = game.player.global_position
	var best_tree: AppleTree = null
	var best_dist := 3.2
	for tree in trees:
		var d := origin.distance_to(tree.global_position)
		if d < best_dist and reachable(game.player, tree):
			best_dist = d
			best_tree = tree
	return best_tree

func reachable(actor: Node3D, tree: AppleTree) -> bool:
	if actor == null or tree == null: return false
	if actor.global_position.distance_to(tree.global_position) > 3.2: return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.6, tree.global_position + Vector3.UP * 1.5, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.get("collider") == tree

func _process(_delta: float) -> void:
	focused_tree = nearest() if (game.world_items != null and game.world_items.focused_kind == "apple_tree") else null
	var key := GamePreferences.binding_text("pickup_weapon", "keyboard")
	for tree in trees:
		var text := ""
		if tree.can_harvest():
			text = "[%s] Shake tree · Drop %d Apples" % [key, AppleTree.APPLE_YIELD]
		else:
			var seconds := ceili(tree.regrow_remaining)
			text = "Fruit returns · %d:%02d" % [seconds / 60, seconds % 60]
		tree.present(tree == focused_tree, text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon") or not available(): return
	if game.world_items.focused_kind != "apple_tree" or focused_tree == null: return
	if not focused_tree.can_harvest(): return
	if request_harvest.is_valid(): request_harvest.call(trees.find(focused_tree))
	else: _pending = focused_tree
	get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if _pending != null and authoritative and available() and _pending == nearest():
		perform(game.player, trees.find(_pending))
	_pending = null

func perform(actor: Player, index: int) -> bool:
	if not authoritative or not game.world_items.pool.authoritative or index < 0 or index >= trees.size(): return false
	var tree := trees[index]
	if not reachable(actor, tree) or not tree.can_harvest(): return false
	if game.world_items.pool.drops.size() >= WorldItemPool.LIMIT:
		if actor == game.player: game.hud.announce("Too many items on the ground. Pick some up first.")
		return false
	game.apple_tree_targets[index].current = 0.0
	tree.react_to_hit(0.0, Vector3.ZERO)
	return tree.harvest() > 0

func _apples_fell(count: int, at: Vector3, tree: AppleTree) -> void:
	if not authoritative or not game.world_items.pool.authoritative: return
	var ground: Vector3 = game.world.ground_point(at.x, at.z)
	var drop: WorldItemDrop = game.world_items.pool.spawn("apple", count, ground, Vector2.ZERO)
	if drop == null:
		tree.apply_world_state(0.0)
		var index := trees.find(tree)
		game.apple_tree_targets[index].current = game.apple_tree_targets[index].maximum
		game.hud.announce("No room for fallen apples. Clear some ground drops and try again.")
		return
	drop.global_position = ground + Vector3.UP * (WorldItemDrop.RADIUS + 0.02)
	drop.last_safe = drop.global_position
	var binding := GamePreferences.binding_text("pickup_weapon", "keyboard")
	CombatEffects.burst(game, at, "%d Apples on ground" % count, Color("ff6b6b"))
	game.hud.announce("%d apples fell. Press %s to pick them up." % [count, binding])
