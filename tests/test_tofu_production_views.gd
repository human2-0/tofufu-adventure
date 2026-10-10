extends SceneTree

var failures: int = 0
var intents: Array[String] = []
var cuts: Array[PackedFloat32Array] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value: return
	failures += 1
	push_error(label)

func run() -> void:
	root.size = Vector2i(960, 720)
	var press := DungeonPressView.new()
	root.add_child(press)
	press.action_requested.connect(func(action: String, _id: String) -> void: intents.append(action))
	press.open(false)
	press.present_trial("", [], false, false, [false, false, false])
	check(press._buttons[2].disabled and press._buttons[6].disabled, "stone and lift controls wait for trial")
	press._choose("soft")
	press._emit("start", "")
	check(intents == ["start"], "press start sends intent")
	press.present_trial("soft", [], true, false, [false, false, false])
	press.present(0, 0, 0)
	check(press._status.text.contains("start the timer") and press._buttons[6].disabled, "press explains timer begins with required stones")
	press.present_trial("soft", ["stone_1"], true, true, [false, false, false])
	press.present(1, 2.5, 0)
	check(not press._buttons[6].disabled and press._buttons[2].disabled and press._status.text.contains("lift at 3s"), "running press gives release target and prevents duplicate stone")
	await capture("traditional")
	press.present_trial("soft", ["stone_1"], true, true, [false, false, false], false)
	press.present(1, 2.5, 0)
	check(press._buttons[6].disabled and press._status.text.contains("Another operator"), "leased press shows waiting state for another player")
	press.close()
	check(intents == ["start"], "forced view close is safe cancellation")
	press.open(true)
	press.present_trial("", [], false, false, [false, false, false])
	check(press._buttons[5].disabled, "modern press explains missing certificates instead of sending ignored start")
	press.present_trial("", [], true, true, [true, true, false])
	press.present(0, 6.8, 85.0)
	await capture("press")
	press._cancel()
	check(intents == ["start", "abandon"], "explicit back signals abandonment")
	check(not press._active and press.is_modern(), "close releases modal state")
	press.open(true)
	press.present_trial("", [], true, true, [true, true, false])
	press.present(0, 6.8, 85.0, "", true)
	check(press._status.text.contains("78–94") and press._preset.text.contains("Wider"), "wider preset explicitly displayed")
	check(is_equal_approx(press._band.anchor_left, 0.78) and is_equal_approx(press._band.anchor_right, 0.94), "gauge draws actual widened stop band")
	press._request_preset()
	check(intents[-1] == "preset", "preset toggle emits authority intent")
	press.close()
	var cutter := DungeonCutterView.new()
	root.add_child(cutter)
	cutter.cuts_committed.connect(func(value: PackedFloat32Array) -> void: cuts.append(value))
	cutter.open()
	cutter.set_guides(PackedFloat32Array([0.15, 0.32, 0.5, 0.68, 0.85]))
	check(cutter._pieces.get_child_count() == 6, "cutter previews six measured pieces")
	check(cutter._widths.text.count("90.0%") == 2 and cutter._widths.text.count("108.0%") == 2, "cutter reports both end widths and each internal width relative to one equal piece")
	await capture("cutter")
	cutter._commit_cuts()
	cutter._commit_cuts()
	check(cuts.size() == 1 and is_equal_approx(cuts[0][0], 0.15), "commit emits edited guides once")
	cutter.show_feedback("Invalid plan; adjust your guides.")
	check(not cutter._commit.disabled, "rejected packet feedback allows edits")
	cutter.set_guides(PackedFloat32Array([0.2, 0.1, 0.5, 0.7, 0.8]))
	check(cutter._preview.text.contains("cross"), "crossed plan gets a readable preview")
	check(cutter._widths.text.contains("in order"), "crossed guides cannot display stale six-width measurements")
	cutter.close()
	var journal := DungeonRecipeJournal.new()
	root.add_child(journal)
	journal.open("Observe each machine's input and output.", false)
	check(not journal._return.visible, "journal hides return action when there is no cargo")
	journal.set_cargo("Mature bean sack")
	check(journal._cargo.text.contains("Mature bean sack") and journal._return.visible and journal._return.text.contains("recovery dock"), "journal names carried cargo and explains its safe return")
	await capture("cargo-journal")
	journal.set_cargo("")
	check(not journal._return.visible and not journal._cargo.visible, "return action disappears after cargo release")
	journal.close()
	journal.queue_free()
	press.queue_free()
	cutter.queue_free()
	await process_frame
	print("Tofu Production Views: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func capture(label: String) -> void:
	if not "--render" in OS.get_cmdline_user_args(): return
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/tofufu-production-" + label + ".png")
