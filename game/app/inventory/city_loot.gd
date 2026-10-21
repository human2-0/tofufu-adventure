class_name CityLoot
extends Node3D
## Finite shared supplies. Only authority validates and commits chest opening.

var game: AdventureGame
var opened: int = 0
var authoritative: bool = true
var request_open: Callable
var chests: Array[GigalopolisChest] = []
var _pending: int = -1

func _ready() -> void:
	for index in CityLootSites.POINTS.size():
		var chest := GigalopolisChest.new()
		chest.name = "CitySupply%02d" % index
		add_child(chest)
		chest.global_position = CityLootSites.position_for(game.world, index)
		chests.append(chest)

func available() -> bool:
	var source: LocalPlayerInput = game.shooting_view.local_input if game.shooting_view != null else null
	return source != null and source.enabled and not source.chat_blocked and game.hud.visible and not game.inventory_window.visible and not game.map.expanded and not game.player.transport_active and game.health.current > 0 and (game.opening == null or not game.opening.active) and (game.solo_arena == null or not game.solo_arena.active())

func reachable(actor: Player, index: int) -> bool:
	if not is_instance_valid(actor) or index < 0 or index >= chests.size() or actor.transport_active or (opened & (1 << index)) != 0: return false
	var at := chests[index].global_position + Vector3.UP * 1.2
	if actor.global_position.distance_to(chests[index].global_position) > 3.0: return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.75, at, 1)
	ray.hit_from_inside = true
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func perform(actor: Player, index: int) -> bool:
	if not authoritative or not game.world_items.pool.authoritative or not reachable(actor, index): return false
	var rows := CityLootSites.contents(index)
	var pool := game.world_items.pool
	if pool.drops.size() + rows.size() > WorldItemPool.LIMIT: return false
	var spawned: Array[int] = []
	for i in rows.size():
		var at := chests[index].global_position + Vector3((i - 0.5) * 1.2, 0, 1.5)
		var drop := pool.spawn(rows[i][0], rows[i][1], at, Vector2.ZERO)
		if drop == null:
			for id in spawned: pool.remove(id)
			return false
		spawned.append(drop.drop_id)
	opened |= 1 << index
	return true

func restore(value: int) -> void:
	opened = value & CityLootSites.MASK
	for index in chests.size(): chests[index].present((opened & (1 << index)) != 0, false)

func _process(_delta: float) -> void:
	var focused := game.world_items.focused_plot if available() and game.world_items.focused_kind == "city_chest" else -1
	for index in chests.size(): chests[index].present((opened & (1 << index)) != 0, index == focused, GamePreferences.binding_text("pickup_weapon", "keyboard"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon") or not available() or game.world_items.focused_kind != "city_chest": return
	var index := game.world_items.focused_plot
	if not reachable(game.player, index): return
	if request_open.is_valid(): request_open.call(index)
	else: _pending = index
	get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if _pending >= 0 and available(): perform(game.player, _pending)
	_pending = -1
