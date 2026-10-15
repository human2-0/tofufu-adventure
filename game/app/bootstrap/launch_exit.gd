class_name LaunchExit
extends RefCounted
## Save before leaving; a disk failure offers retry or an explicit discard choice.

static func return_title(app: Node, discard: bool = false) -> void:
	if not discard and not app._save():
		_failed(app, false)
		return
	if app._online:
		app._online = false
		app.connection.disconnect_session()
	app._clear_game()
	app._home()

static func quit(app: Node, discard: bool = false) -> void:
	if app._quitting: return
	if not discard and not app._save():
		_failed(app, true)
		return
	app._quitting = true
	app.loader.cancel()
	if is_instance_valid(app.game): app.game.process_mode = Node.PROCESS_MODE_DISABLED
	await app.connection.shutdown()
	app.get_tree().quit()

static func _failed(app: Node, exiting: bool) -> void:
	if app.menu.has_node("SaveFailure"): return
	var dialog := ConfirmationDialog.new()
	dialog.name = "SaveFailure"
	dialog.title = "Adventure could not be saved"
	dialog.dialog_text = app.menu.note.text + "\nYour previous save is safe. Leaving now loses progress since the last successful save."
	dialog.ok_button_text = "Quit without saving" if exiting else "Leave without saving"
	dialog.cancel_button_text = "Keep playing"
	app.menu.add_child(dialog)
	dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog.get_label().custom_minimum_size.x = minf(520, app.menu.get_viewport_rect().size.x - 60)
	var retry := dialog.add_button("Retry save", false, "retry")
	retry.pressed.connect(func() -> void:
		app.menu.remove_child(dialog)
		dialog.queue_free()
		if exiting: quit(app)
		else: return_title(app))
	dialog.confirmed.connect(func() -> void:
		app.menu.remove_child(dialog)
		dialog.queue_free()
		if exiting: quit(app, true)
		else: return_title(app, true))
	dialog.canceled.connect(func() -> void:
		app.menu.remove_child(dialog)
		dialog.queue_free()
		app._resume())
	dialog.popup_centered(Vector2i(mini(620, int(app.menu.get_viewport_rect().size.x) - 40), 210))
	MenuStyle.focus_later(retry)
