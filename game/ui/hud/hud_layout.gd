class_name HUDLayout
extends RefCounted
## Constructs HUD controls and connects presentation callbacks.

static func ready(hud: HUD) -> void:
	var canvas := Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(canvas)
	hud._smear = SnailSmear.new()
	canvas.add_child(hud._smear)
	hud._soy_hit = SoyHitFlash.new()
	canvas.add_child(hud._soy_hit)

	var heading := HUDElements.make_panel(canvas, Vector2(16, 16), Vector2(210, 58), Vector2(0, 0))
	HUDElements.make_label(heading, "TOFUFU / FUFUFARM", 13, Color("f5dfac"))
	hud._session = HUDElements.make_label(heading, "Chapter 01 · Tab for guide", 11, Color("baccc0"))
	hud._clock = HUDElements.make_label(heading, "", 11, Color("b8d7dd"))

	var ledger := HUDElements.make_panel(canvas, Vector2(-232, 16), Vector2(216, 235), Vector2(1, 0))
	hud._ledger = ledger.get_parent() as PanelContainer
	hud._stats = HUDElements.make_label(ledger, "", 10, Color("d8e3d2"))
	hud._character = CharacterStats.new()
	hud._character.stat_point_allocated.connect(func(k: String) -> void: hud.stat_point_allocated.emit(k))
	ledger.add_child(hud._character)

	var health := HUDElements.make_panel(canvas, Vector2(16, -138), Vector2(210, 124), Vector2(0, 1))
	hud._health_text = HUDElements.make_label(health, "FUFU / 100 HP", 12, Color("dbe8c1"))
	hud._health_bar = HUDElements.make_bar(health, Color("a3cc86"), 170, 7)
	hud._stamina_text = HUDElements.make_label(health, "100 / 100 SP", 12, Color("aee6e8"))
	hud._stamina_bar = HUDElements.make_bar(health, Color("70cbd4"), 170, 7)
	hud._stamina_bar.value = 100
	hud._equipment = HUDElements.make_label(health, "[1] KNIFE   2 FISTS   3 GUN", 11, Color("aee6d0"))
	hud._healing_label = HUDElements.make_label(health, "", 10, Color("c8efa0"))
	hud._healing_label.visible = false

	var charge := HUDElements.make_panel(canvas, Vector2(-206, -58), Vector2(190, 42), Vector2(1, 1))
	hud._charge_text = HUDElements.make_label(charge, "HOLD LMB / CHARGE", 11, Color("f5dfac"))
	hud._charge_bar = HUDElements.make_bar(charge, Color("efc477"), 170, 6)

	setup_center(hud, canvas)
	hud.show_progress(0, 0, 0)

static func setup_center(hud: HUD, canvas: Control) -> void:
	hud._run_meter = RunMeter.new()
	canvas.add_child(hud._run_meter)
	hud._run_meter.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud._run_meter.offset_left = -95
	hud._run_meter.offset_right = 95
	hud._run_meter.offset_top = -140
	hud._run_meter.offset_bottom = -112
	hud._jump_meter = JumpMeter.new()
	canvas.add_child(hud._jump_meter)
	hud._jump_meter.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud._jump_meter.offset_left = -85
	hud._jump_meter.offset_right = 85
	hud._jump_meter.offset_top = -98
	hud._jump_meter.offset_bottom = -72
	hud._jump_bar = hud._jump_meter.jump_bar
	hud._jump_text = hud._jump_meter.jump_text

	hud._dash_slot = DashSlot.new()
	canvas.add_child(hud._dash_slot)
	hud._dash_slot.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud._dash_slot.offset_left = -26
	hud._dash_slot.offset_right = 26
	hud._dash_slot.offset_top = -68
	hud._dash_slot.offset_bottom = -16
	hud.dash_bar = hud._dash_slot.dash_bar
	hud.dash_status = hud._dash_slot.dash_status

	hud._popup = KawaiiPopup.new()
	canvas.add_child(hud._popup)
	hud._popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hud._popup.offset_left = -150
	hud._popup.offset_right = 150
	hud._popup.offset_top = 40
	hud._popup.offset_bottom = 110

	_help_and_notice(hud, canvas)

static func _help_and_notice(hud: HUD, canvas: Control) -> void:
	var help_box := HUDElements.make_panel(canvas, Vector2(-180, 110), Vector2(360, 220), Vector2(0.5, 0))
	hud._help = help_box.get_parent() as PanelContainer
	HUDElements.make_label(help_box, "FUFU ADVENTURE GUIDE", 13, Color("f5dfac"))
	HUDElements.make_label(help_box, "WASD: Walk • Ctrl / L3: Run • Mouse: Aim • Space: Leap • Shift: Dash / hold 0.66s for Super Dash • LMB: Tap combo / hold power (25 SP)\nRMB: Knife guard / Staff tornado / Podburst. Nori: hold RMB, steer with WASD, release to plunge (75 SP).\nSuper Dash lasts twice as long, passes through actors and leaves a light-damage fart cloud.\nMelee: attack mid-air for a diving slash. Hit, then fast tap to stab; hold the next combo hit to launch foes.\nAccurate hits briefly raise critical chance. 1/2: Combat slots • I / B: Inventory & EQ • 3–6: Support slots\nQ: Drop held weapon • E: Pick up highlighted item • Tab: Guide • C: Camera • Enter: Chat • V: Voice", 10, Color("d1ddd0"))
	hud._help.visible = false

	hud._notice = Label.new()
	hud._notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud._notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud._notice.add_theme_font_size_override("font_size", 13)
	hud._notice.add_theme_color_override("font_color", Color("fff0c2"))
	canvas.add_child(hud._notice)
	hud._notice.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hud._notice.offset_left = -250
	hud._notice.offset_right = 250
	hud._notice.offset_top = 118
	hud._notice.offset_bottom = 146
