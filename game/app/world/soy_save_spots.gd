class_name SoySaveSpots
extends Node3D
## Authored save plants, shared focus and authoritative personal claiming.

var game: AdventureGame
var ownership := SoySpotOwnership.new()
var spots: Array[SoySaveSpot] = []
var authoritative: bool = true
var request_claim: Callable
var _pending: int = -1

func _ready() -> void:
	for index in SoySaveSpotSites.IDS.size():
		var spot: SoySaveSpot = preload("res://game/world/common/soy_save_spot.tscn").instantiate()
		var at := SoySaveSpotSites.POINTS[index]
		spot.position = game.world.ground_point(at.x, at.y, 0.02)
		if SoySaveSpotSites.IDS[index] == "clouds": spot.position = CloudTerrain.point(at.x, at.y, 0.02)
		spot.title = SoySaveSpotSites.TITLES[index]
		spot.name = SoySaveSpotSites.IDS[index]
		add_child(spot)
		spots.append(spot)

func available() -> bool:
	var source: LocalPlayerInput = game.shooting_view.local_input if game.shooting_view != null else null
	return game.hud.visible and source != null and source.enabled and not source.chat_blocked and not game.inventory_window.visible and not game.map.expanded and not game.player.transport_active and game.health.current > 0.0 and (game.opening == null or not game.opening.active) and (game.solo_arena == null or not game.solo_arena.active())

func reachable(actor: Player, index: int) -> bool:
	if index < 0 or index >= spots.size() or actor.transport_active: return false
	var spot := spots[index]
	if actor.global_position.distance_to(spot.global_position) > 3.2: return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.65, spot.global_position + Vector3.UP * 0.65, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _process(_delta: float) -> void:
	var index := game.world_items.focused_plot if available() and game.world_items.focused_kind == "soy_spot" else -1
	var key := GamePreferences.binding_text("pickup_weapon", "keyboard")
	for i in spots.size(): spots[i].present(ownership.owns(i), i == index, key)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon") or not available(): return
	if game.world_items.focused_kind != "soy_spot": return
	var index := game.world_items.focused_plot
	if not reachable(game.player, index): return
	if not ownership.owns(index):
		if request_claim.is_valid(): request_claim.call(index)
		else: _pending = index
	get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if _pending >= 0 and available():
		if perform(game.player, ownership, _pending): game.hud.announce("Soybean save spot claimed · %s" % spots[_pending].title)
	_pending = -1

func perform(actor: Player, personal: SoySpotOwnership, index: int) -> bool:
	if not authoritative or not reachable(actor, index): return false
	return personal.claim(index)
