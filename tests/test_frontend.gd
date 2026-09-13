extends SceneTree

var failures: int = 0
func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var app: Node = load("res://game/app/launch.tscn").instantiate()
	var base := "user://test_frontend_%d" % Time.get_ticks_usec()
	app.store.directory = base
	app.preferences.path = base + ".cfg"
	root.add_child(app)
	await process_frame
	check(app.menu.visible and app.game == null, "launch opens menu without starting gameplay")
	check(app.transport._child.is_empty(), "offline launch never starts a sidecar")
	app.saves.show_saves()
	app.saves.show_new()
	app._start(0, {"name": "Test adventure", "opening_complete": true})
	await physics_frame
	check(not app.menu.visible and app.game != null, "new game begins from menu")
	app.game.player.position = Vector3(3, 0.2, 2)
	app.game.encounters.experience = 125
	app.game.progression.progress.award_experience(125)
	for hit in 27: app.game.progression.progress.weapon_hit("sword")
	app.game.progression.progress.mana_spent(13)
	app.game.health.current = 63
	app.game.combat.equipment.knife_selected = false
	check(app._save(), "save succeeds")
	var record: Dictionary = app.store.read_slot(0)
	check(record.experience == 125 and record.health == 63, "save contains progress and health")
	app._return_title()
	await process_frame
	check(app.game == null and app.menu.visible, "return to title unloads game")
	app._start(0, record)
	await process_frame
	check(app.game.encounters.experience == 125 and app.game.health.current == 63, "continue restores adventure")
	check(app.game.progression.progress.level() == 2 and app.game.progression.progress.practice.sword == 27 and app.game.progression.progress.practice.magic == 13, "solo continue restores levels and partial skill practice")
	check(app.game.combat.sword_damage_multiplier > 1 and app.game.player.motor.walk_multiplier > 1, "restoring re-applies progression bonuses")
	check(not app.game.combat.equipment.knife_selected, "continue restores selected equipment")
	check(app.game.player.position.x > 2.9, "continue restores position")
	var invalid := record.duplicate(true)
	invalid.position = [999999, 0, 0]
	check(not app.store.write_slot(0, invalid), "invalid state cannot overwrite a save")
	check(app.store.read_slot(0).experience == 125, "previous save preserved on invalid write")
	app._return_title()
	app.settings.show_settings()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	key.pressed = true
	check(app.preferences.bind_action("jump", key, "keyboard").is_empty(), "keyboard rebind saves")
	check(not app.preferences.bind_action("dash", key, "keyboard").is_empty(), "conflicting binding rejected")
	var loaded := GamePreferences.new()
	loaded.path = app.preferences.path
	loaded.load_preferences()
	check(GamePreferences.binding_text("jump", "keyboard").contains("J"), "binding survives reload")
	key.physical_keycode = KEY_ESCAPE
	check(not app.preferences.bind_action("jump", key, "keyboard").is_empty(), "Escape remains available")
	loaded.reset_controls()
	app.lobby.show_lobby()
	check(app.lobby.panel != null and app.transport._child.is_empty(), "lobby waits for explicit discovery")
	var input := {"sequence": 1, "ack": 0, "weapon_slot": 0, "move": [1, 0], "aim": [0, 1], "dash": [1, 0], "jump_held": false, "jump_pressed": true, "dash_pressed": false}
	for field in ExplorationProtocol.INPUT_FLAGS:
		if not input.has(field): input[field] = false
	check(ExplorationProtocol.valid_input(input), "valid remote intent accepted")
	input.move = [1, 1]
	check(not ExplorationProtocol.valid_input(input), "overspeed diagonal rejected")
	input.move = [NAN, 0]
	check(not ExplorationProtocol.valid_input(input), "nonfinite remote intent rejected")
	var remote := RemotePlayerInput.new()
	var command := PlayerCommand.new()
	command.jump_pressed = true
	command.jump_held = true
	remote.accept(command)
	check(remote.sample(Vector3.ZERO).jump_pressed, "remote jump edge delivered")
	check(not remote.sample(Vector3.ZERO).jump_pressed, "remote jump edge consumed once")
	remote.free()
	app.store.remove_slot(0)
	DirAccess.remove_absolute(base)
	DirAccess.remove_absolute(app.preferences.path)
	app.queue_free()
	await process_frame
	print("Frontend tests: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
