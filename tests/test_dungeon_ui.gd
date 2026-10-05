extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	var return_button := Button.new()
	return_button.text = "Return focus"
	host.add_child(return_button)
	return_button.grab_focus()
	var terminal := DungeonTerminalView.new()
	root.add_child(terminal)
	await process_frame
	terminal.open()
	await process_frame
	_check(terminal.visible, "terminal opens")
	var submitted: Array[String] = []
	terminal.password_submitted.connect(func(raw_text: String) -> void: submitted.append(raw_text))
	terminal._field.text = " tofufu "
	terminal._submit_password()
	_check(submitted == [" tofufu "], "terminal emits raw input")
	terminal.close()
	await process_frame
	_check(root.gui_get_focus_owner() == return_button, "terminal restores focus")
	var note := DungeonNoteView.new()
	root.add_child(note)
	await process_frame
	note.open()
	_check(note.visible and DungeonNoteView.NOTE_TEXT.contains("Tofufu"), "note opens with clue")
	note.close()
	var cutter := DungeonCutterView.new()
	root.add_child(cutter)
	await process_frame
	var plans: Array[PackedFloat32Array] = []
	cutter.cuts_committed.connect(func(plan: PackedFloat32Array) -> void: plans.append(plan))
	cutter.open()
	cutter._commit_cuts()
	_check(plans.size() == 1 and plans[0].size() == 5, "cutter emits five guides once")
	cutter._commit_cuts()
	_check(plans.size() == 1, "cutter blocks repeat while pending")
	cutter.close()
	var adapter := DungeonPuzzleViews.new()
	root.add_child(adapter)
	await process_frame
	var commands: Array[TofuPuzzleCommand] = []
	adapter.command_requested.connect(func(command: TofuPuzzleCommand) -> void: commands.append(command))
	adapter.attempt = TofuDungeonAttempt.new()
	adapter._active_view = "terminal"
	adapter._password(" Tofufu ")
	_check(commands.size() == 1 and commands[0].action == TofuPuzzleCommand.Action.SUBMIT_PASSWORD, "adapter emits typed password intent")
	_check(commands[0].text == " Tofufu " and commands[0].valid_shape(), "adapter preserves bounded raw password")
	adapter.attempt.cut.issue_block("block_test", 6.0)
	adapter._active_view = "cutter"
	adapter._cuts(PackedFloat32Array([0.16, 0.33, 0.5, 0.67, 0.84]))
	_check(commands.size() == 2 and commands[1].cuts.size() == 5, "adapter emits five absolute cut positions")
	_check(absf(commands[1].cuts[0] - 0.96) < 0.001 and commands[1].object_id == "block_test", "adapter uses current block")
	print("Dungeon UI tests: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
