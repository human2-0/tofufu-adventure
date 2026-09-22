class_name SoybeanFarming
extends Node3D
## Nursery composition: explicit plot rules, reach checks, and bag grants.

var game: Node3D
var plots: Array[SoybeanPlot] = []
var focused: SoybeanPlot
var authoritative: bool = true
var request_action: Callable
var simulation_enabled: Callable
var _pending: SoybeanPlot

func _ready() -> void:
	for i in 4:
		var plot := SoybeanPlot.new()
		plot.position = game.world.ground_point(-8.0 + (i % 2) * 2.7, 3.5 + (i / 2) * 2.7, 0.05)
		add_child(plot)
		plots.append(plot)
		if i >= 2:
			plot.crop.plant()
			plot.crop.age = 18.0 if i == 2 else SoybeanCrop.GROW_SECONDS
	MeadowGeometry.signpost(self, game.world.ground_point(-9.9, 3.5), "SOY TEST GARDEN\nFree seeds · 30s growth\nPlant / harvest nearby")

func available() -> bool:
	var source: LocalPlayerInput = game.shooting_view.local_input
	return game.hud.visible and source != null and source.enabled and not source.chat_blocked and not game.inventory_window.visible and not game.map.expanded

func nearest() -> SoybeanPlot:
	if not available() or game.world_items.focused_id != 0: return null
	var result: SoybeanPlot
	var distance := 2.2
	for plot in plots:
		var d: float = game.player.global_position.distance_to(plot.global_position)
		if d >= distance: continue
		if not reachable(game.player, plot): continue
		distance = d
		result = plot
	return result

func _process(_delta: float) -> void:
	focused = nearest()
	for plot in plots:
		var text := plot.crop.title()
		var key := GamePreferences.binding_text("pickup_weapon", "keyboard")
		match plot.crop.phase():
			SoybeanCrop.Phase.EMPTY: text = "[%s] Plant soybean · free test seed" % key
			SoybeanCrop.Phase.RIPE: text = "[%s] Harvest · +3 soybeans" % key
			SoybeanCrop.Phase.HARVEST: pass
			_: text += " · %ds" % ceili(SoybeanCrop.GROW_SECONDS - plot.crop.age)
		plot.present(plot == focused, text)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("pickup_weapon"): return
	var plot := nearest()
	if plot == null: return
	if request_action.is_valid():
		request_action.call(plots.find(plot), plot.crop.revision, "plant" if plot.crop.phase() == SoybeanCrop.Phase.EMPTY else "harvest")
	else:
		_pending = plot
	get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not authoritative or (simulation_enabled.is_valid() and not simulation_enabled.call()) or (not simulation_enabled.is_valid() and not game.hud.visible):
		_pending = null
		return
	for plot in plots: plot.crop.step(delta)
	if _pending != null and _pending == nearest(): interact(_pending)
	_pending = null

func interact(plot: SoybeanPlot) -> bool:
	if not authoritative or plot not in plots or plot != nearest(): return false
	var message := perform(game.player, game.inventory, plots.find(plot), plot.crop.revision, "plant" if plot.crop.phase() == SoybeanCrop.Phase.EMPTY else "harvest")
	if not message.is_empty(): game.hud.announce(message)
	return message.begins_with("Planted") or message.begins_with("Harvested")

func reachable(actor: Node3D, plot: SoybeanPlot) -> bool:
	if actor.global_position.distance_to(plot.global_position) >= 2.2: return false
	var ray := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP * 0.6, plot.global_position + Vector3.UP * 0.5, 1)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func perform(actor: Node3D, inventory: PlayerInventory, id: int, revision: int, action: String) -> String:
	if not authoritative or id < 0 or id >= plots.size(): return ""
	var plot := plots[id]
	if not reachable(actor, plot) or revision != plot.crop.revision: return ""
	if action == "plant":
		return "Planted soybean! Ready in 30 seconds." if plot.crop.plant() else ""
	if action != "harvest" or plot.crop.phase() != SoybeanCrop.Phase.RIPE: return ""
	var bean := InventoryItem.create_soybean()
	if not inventory.has_space_for(bean, SoybeanCrop.YIELD):
		return "Bag full · make room for 3 soybeans, then harvest."
	if not plot.crop.harvest(): return ""
	inventory.add_item(bean, SoybeanCrop.YIELD)
	_harvest_effect(plot)
	return "Harvested 3 soybeans! Ready to replant."

func capture() -> Array:
	var rows: Array = []
	for plot in plots:
		rows.append([plot.crop.planted, plot.crop.age, plot.crop.harvest_time, plot.crop.revision])
	return rows

func restore(rows: Array) -> void:
	if not WorldProtocol.farming(rows): return
	for i in plots.size():
		var crop := plots[i].crop
		if rows[i][2] > 0 and crop.harvest_time <= 0: _harvest_effect(plots[i])
		crop.planted = rows[i][0]
		crop.age = float(rows[i][1])
		crop.harvest_time = float(rows[i][2])
		crop.revision = int(rows[i][3])

func _harvest_effect(plot: SoybeanPlot) -> void:
	CombatEffects.burst(self, plot.global_position + Vector3.UP, "+3 SOYBEANS", Color("ffdb76"))
