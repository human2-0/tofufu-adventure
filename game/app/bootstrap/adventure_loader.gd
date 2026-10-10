class_name AdventureLoader
extends Node
## Defers expensive world resources until after the landing screen is visible.

const WORLD_PATH := "res://game/app/adventure/main.tscn"
var view: LoadingView
var busy: bool = false
var _generation: int = 0

func open(parent: Node, preferences: GamePreferences, data: Dictionary, online: bool, path: String = WORLD_PATH) -> AdventureGame:
	if busy: return null
	busy = true
	_generation += 1
	var generation := _generation
	view.begin(str(data.get("name", "Our meadow")), online)
	# Two frames let the loading overlay draw before resource/scene work begins.
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _generation: return null
	if not ResourceLoader.exists(path):
		_failed("The world scene is missing. Return to title and try again.")
		return null
	var state := ResourceLoader.load_threaded_get_status(path)
	if state not in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED]:
		var error := ResourceLoader.load_threaded_request(path, "PackedScene")
		if error != OK:
			_failed("The world could not be loaded. Return to title and try again.")
			return null
	var amounts: Array = []
	while generation == _generation:
		state = ResourceLoader.load_threaded_get_status(path, amounts)
		if state == ResourceLoader.THREAD_LOAD_LOADED: break
		if state != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_failed("The world could not be loaded. Return to title and try again.")
			return null
		view.stage("Gathering the world…", float(amounts[0]) * 75 if not amounts.is_empty() else 0)
		await get_tree().process_frame
	if generation != _generation: return null
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	if packed == null:
		_failed("The world scene is unavailable. Return to title and try again.")
		return null
	view.stage("Building your world…", 80)
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _generation: return null
	var world := packed.instantiate() as AdventureGame
	if world == null:
		_failed("The world scene is invalid. Return to title and try again.")
		return null
	world.play_opening = not data.get("opening_complete", false)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(world)
	world.map.configure_preferences(preferences)
	view.stage("Restoring your adventure…", 95)
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != _generation:
		world.queue_free()
		return null
	if data.has("version"): AdventureSnapshot.restore(world, data)
	return world

func finish() -> void:
	busy = false
	view.hide()

func cancel() -> void:
	_generation += 1
	finish()

func _failed(message: String) -> void:
	busy = false
	view.fail(message)
