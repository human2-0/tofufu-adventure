class_name BattleLobbyState
extends RefCounted
## Lobby values, settings ownership and minimum viable team count.

static func refresh(flow: BattleRoyaleFlow) -> void:
	if is_instance_valid(flow.game): return
	if not is_instance_valid(flow.panel) or not is_instance_valid(flow.app.menu) or not flow.panel.is_inside_tree(): return
	flow.panel.show_career(flow.rounds.career.caption(), flow.rounds.career.records())
	var names := PackedStringArray()
	var online := flow.room != null and flow.room.phase not in ["idle", "ended"]
	if flow.room != null:
		for row: Dictionary in flow.room.members: names.append(row.name)
	var message := flow.tr(flow.room.status) if flow.room != null else flow.tr("Choose a Tofufu and a match type")
	if flow.room != null and flow.room.phase == "waiting" and flow.room.auto_queue:
		message += "\n" + flow.tr("Match starts in %ds") % maxi(0, ceili(flow.room.deadline - flow.room.clock))
	var options: Array = flow.room.options if online else flow._options
	var humans := maxi(1, names.size())
	var cpus := BattleOptions.cpu_count(options, humans)
	flow.panel.cpu_options.display(int(options[0]), int(options[1]), cpus, humans + cpus, not online or (flow.room.authority() and flow.room.phase == "waiting"), BattleOptions.duos(options))
	flow.panel.practice_button.disabled = not BattleOptions.playable(options, 1)
	flow.panel.practice_button.tooltip_text = BattleOptions.minimum_message(options) if not BattleOptions.playable(options, 1) else ""
	flow.panel.start_button.disabled = not BattleOptions.playable(options, humans)
	flow.panel.duos = BattleOptions.duos(options)
	flow.panel.show_state(message, names, flow.room != null and flow.room.authority(), flow.room != null and flow.room.phase == "waiting", online)

