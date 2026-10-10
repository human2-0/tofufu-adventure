class_name LobbyPanel
extends VBoxContainer

signal discover(name: String)
signal nickname_changed(name: String)
signal host(slot: int)
signal join(key: String)
signal begin
signal leave
signal back
var can_host: bool = true
var discovery_description: String = ""
var nickname: String = "Fufu"
var status: Label
var identity: LobbyIdentity
var pulse: DiscoveryPulse
var footer: HBoxContainer
var _peers: VBoxContainer
var _host: Button
var _begin: Button
var _leave: Button
var _discover: Button
var _adventures: OptionButton
var _hosting_section: VBoxContainer
var _signature: String = ""

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	identity = LobbyIdentity.new()
	identity.nickname = nickname
	add_child(identity)
	identity.submitted.connect(nickname_changed.emit)
	var activity := HBoxContainer.new()
	add_child(activity)
	pulse = DiscoveryPulse.new()
	activity.add_child(pulse)
	status = MenuStyle.paragraph(activity, "")
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_discover = MenuStyle.button(self, "Retry finding friends" if can_host else "Connect to server", func() -> void: discover.emit(identity.nickname), MenuIcons.SEARCH)
	_build_host()
	MenuStyle.section(self, "Join a world", MenuIcons.FRIENDS)
	_peers = VBoxContainer.new()
	add_child(_peers)
	_leave = MenuStyle.button(self, "Cancel joining", leave.emit, MenuIcons.EXIT)
	footer = HBoxContainer.new()
	add_child(footer)
	var back_button := MenuStyle.button(footer, "Back to title", back.emit, MenuIcons.EXIT)
	back_button.custom_minimum_size.y = 40
	MenuStyle.focus_later(back_button)
	get_viewport().size_changed.connect(_responsive)
	_responsive()

func _build_host() -> void:
	var section := VBoxContainer.new()
	_hosting_section = section
	section.visible = can_host
	add_child(section)
	MenuStyle.section(section, "Host a world", MenuIcons.WORLD)
	var note := MenuStyle.paragraph(section, "Start exploring now. Up to 3 friends can join you later. The host saves everyone’s progress.")
	note.add_theme_font_size_override("font_size", 14)
	_adventures = OptionButton.new()
	_adventures.fit_to_longest_item = false
	_adventures.add_item("New shared adventure", 100)
	section.add_child(_adventures)
	_host = MenuStyle.button(section, "Host world", func() -> void: host.emit(-1 if _adventures.get_selected_id() == 100 else _adventures.get_selected_id()), MenuIcons.WORLD)
	_host.add_theme_stylebox_override("normal", MenuStyle.button_box("primary"))
	_begin = MenuStyle.button(section, "Enter world", begin.emit, MenuIcons.ARROW)

func update_state(peers: Dictionary, local_key: String, host_key: String, hosting: bool, count: int, message: String, pending: String = "") -> void:
	status.text = message
	_hosting_section.visible = can_host and (hosting or (host_key.is_empty() and pending.is_empty()))
	_adventures.disabled = not host_key.is_empty() or not pending.is_empty()
	var host_was_disabled := _host.disabled
	_host.disabled = local_key.is_empty() or not host_key.is_empty() or not pending.is_empty()
	if host_was_disabled and not _host.disabled: MenuStyle.focus_later(_host)
	_begin.visible = hosting
	_begin.disabled = count < 1
	var leave_was_visible := _leave.visible
	_leave.visible = not host_key.is_empty() or not pending.is_empty()
	if not leave_was_visible and _leave.visible: MenuStyle.focus_later(_leave)
	_leave.text = "Cancel joining" if not pending.is_empty() else "Leave world"
	identity.set_locked(not host_key.is_empty() or not pending.is_empty())
	var signature := JSON.stringify(peers) + host_key + pending
	if signature == _signature: return
	_signature = signature
	for child in _peers.get_children():
		_peers.remove_child(child)
		child.queue_free()
	if peers.is_empty():
		MenuStyle.paragraph(_peers, "Friends appear here when they open co-op. They can host a world for you to join." if can_host else "Connect to the server to find its shared world.")
	for key: String in peers:
		_add_peer(key, peers[key], host_key, pending)
	_responsive()

func show_connection(active: bool, failed: bool, connected: bool, pending: bool) -> void:
	pulse.failed = failed
	pulse.active = (active or pending) and not failed
	var retry_was_visible := _discover.visible
	_discover.visible = failed or (not can_host and not connected)
	if failed and not retry_was_visible: MenuStyle.focus_later(_discover)
	_discover.disabled = active and not failed
	if not active and not failed: pulse.queue_redraw()
	if not can_host and not active and not failed and not connected:
		status.text = "Choose your connection file below, then connect."

func _add_peer(key: String, peer: Dictionary, host_key: String, pending: String) -> void:
	var row := VBoxContainer.new()
	_peers.add_child(row)
	var label := MenuStyle.paragraph(row, "%s · %s" % [peer.name, "Exploring" if peer.busy else ("World open" if peer.hosting else "Choosing a world")])
	label.add_theme_color_override("font_color", MenuStyle.CREAM)
	var button := MenuStyle.button(row, "Connecting…" if key == pending else "Join world", func() -> void: join.emit(key), MenuIcons.ARROW)
	button.disabled = not peer.hosting or not host_key.is_empty() or not pending.is_empty()

func set_adventures(saves: Array[Dictionary]) -> void:
	for save in saves:
		if save.valid: _adventures.add_item("Continue · " + str(save.data.name), int(save.slot))

func select_adventure(slot: int) -> void:
	for index in _adventures.item_count:
		if _adventures.get_item_id(index) == slot: _adventures.select(index)

func _responsive() -> void:
	if not is_inside_tree(): return
	var compact := get_viewport_rect().size.y < 460
	_fit_controls(self, compact)
	for button: Button in [_leave, _discover, identity._edit]:
		button.custom_minimum_size.y = 36 if compact else 40
	for button: Button in footer.get_children():
		button.custom_minimum_size.y = 36 if compact else 40

func _fit_controls(parent: Node, compact: bool) -> void:
	for item in parent.get_children():
		if item is Button: MenuStyle.fit_button(item, compact)
		elif item is Label:
			if not item.has_meta("normal_font"): item.set_meta("normal_font", item.get_theme_font_size("font_size"))
			var font: int = item.get_meta("normal_font")
			item.add_theme_font_size_override("font_size", mini(font, 14) if compact else font)
		_fit_controls(item, compact)
