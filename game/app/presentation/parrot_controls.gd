class_name ParrotControls
extends Node
## Local boarding/landing intents and remappable flight hints.

var travel: ParrotTravel
var view := ParrotTravelView.new()
var request_action: Callable

func _ready() -> void:
	add_child(view)
	view.action_requested.connect(_action)

func _process(_delta: float) -> void:
	var game := travel.game
	var source := game.shooting_view.local_input
	view.visible = game.hud.visible
	var active := source != null and source.enabled and not source.chat_blocked and not get_tree().paused
	var riding := game.player.transport_active
	view.action_button.visible = active and (riding or travel.available(game.player))
	view.action_button.text = "Land parrot" if riding else "Ride parrot"
	view.prompt.text = ""
	if riding:
		view.prompt.text = "Steer: movement controls · Rise [%s] · Descend [%s] · Land [%s]\nMap [%s] · Cloud Realm: rise high above Jadewild Jungle" % [GamePreferences.binding_text("jump", "keyboard"), GamePreferences.binding_text("dash", "keyboard"), GamePreferences.binding_text("pickup_weapon", "keyboard"), GamePreferences.binding_text("toggle_map", "keyboard")]
	elif active and travel.available(game.player) and game.world_items.focused_kind == "parrot":
		view.prompt.text = "[%s] Ride parrot · Fly freely" % GamePreferences.binding_text("pickup_weapon", "keyboard")

func _action() -> void:
	var action := "land" if travel.game.player.transport_active else "mount"
	if request_action.is_valid(): request_action.call(action)
	elif action == "land": travel.request_land(travel.game.player)
	else: travel.start(travel.game.player)

func _unhandled_input(event: InputEvent) -> void:
	var game := travel.game
	var source := game.shooting_view.local_input
	if event.is_echo() or not event.is_action_pressed("pickup_weapon"): return
	if source == null or not source.enabled or source.chat_blocked or not game.hud.visible: return
	if not game.player.transport_active:
		if game.world_items.focused_kind != "parrot" or not travel.available(game.player): return
	_action()
	get_viewport().set_input_as_handled()
