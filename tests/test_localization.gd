extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TranslationServer.set_locale("pl")
	var early := Label.new()
	early.text = "BAG · 20 SLOTS"
	root.add_child(early)
	GamePreferences.install_translations(self)
	var early_reference := Label.new()
	early_reference.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	early_reference.text = "TORBA · 20 MIEJSC"
	root.add_child(early_reference)
	await process_frame
	_check(early.get_minimum_size().is_equal_approx(early_reference.get_minimum_size()), "translation installed after child composition")
	early.queue_free()
	early_reference.queue_free()
	_expect(tr("New adventure   →"), "Nowa przygoda   →", "landing")
	_expect(tr("Soybean gun"), "Sojomat", "weapon name")
	_expect(tr("Tofufu"), "Tofufu", "character identity")
	_expect(tr("GODFUFU\nKing of the Cloud Realm"), "GODFUFU\nKról Chmurokrólestwa", "world sign")
	_expect(tr("Bought Knife for 3 Mature Beans. Equipped immediately."), "Zakup: Nożyk za 3 × Fasola Dojrzałucha. Założono od razu.", "rule message")
	_expect(tr("Playing as Apple"), "Grasz jako Apple", "nickname")
	_expect(tr("Adventure saved / Apple"), "Przygoda zapisana / Apple", "adventure name")
	_expect(tr("Apple WINS THE DUEL! FIRST TO 10."), "Apple WYGRYWA POJEDYNEK! 10 PUNKTÓW.", "duel nickname")
	_expect(tr("Knife ✦ Enhanced ×2"), "Nożyk ✦ Wzmocniona ×2", "enhanced tooltip")
	_expect(tr("BAG · 20 SLOTS"), "TORBA · 20 MIEJSC", "bag count")
	_expect(tr("RELOADING · 1.5s · 2 / 9"), "PRZEŁADOWANIE · 1.5s · 2 / 9", "reload")
	_expect(tr("CLEAR · Calm fields"), "BEZCHMURNIE · Spokojne pola", "forecast fragment")
	_expect(tr("RAIN · Snails thriving!\n5 per camp · stronger · faster respawns"), "DESZCZ · Ślimaki szaleją!\n5 w obozie · silniejsze · szybciej wracają", "rain forecast")
	_expect(tr("Public · 2/4 beans · 18 ms RTT · 60 Hz · Server saves"), "Publiczna · 2/4 fasolek · 18 ms RTT · 60 Hz · Serwer zapisuje", "guest language")
	_expect(tr("Soypod Armor"), "Strąkozbroja", "apparel name")
	_expect(tr("Apple {0} SURRENDERED / Knife {1} WINS"), "Apple {0} PODDAJE SIĘ / Knife {1} WYGRYWA", "opaque nickname placeholders")
	_expect(tr("Citric\nAcid"), "Kwas\ncytrynowy", "generated bottle label")
	_expect(tr("Carrying: Nigari bottle\nE · Inspect intake"), "Niesiesz: Butelka: Nigari\nE · Obejrzyj zasypnik", "factory cargo")
	_expect(tr("[E] Pick up Knife ×17"), "[E] Podnieś Nożyk ×17", "ground pickup")
	_expect(tr("Are you sure you want to drop Knife ×17 onto the ground?"), "Wyrzucić przedmiot „Nożyk ×17” na ziemię?", "drop dialog")
	_expect(tr("Soft · 1 / 2 stones\nElapsed 1.25s · lift at 5s (±0.75s)"), "Miękkie · 1 / 2 kamieni\nCzas 1.25s · podnieś przy 5s (±0.75s)", "press timer")
	_check_character_copy()
	_check_templates()
	_check_items()
	for count in [1, 2, 5, 12, 22, 112]:
		var form: String = "punkt cech" if count == 1 else ("punkty cech" if count % 10 in [2, 3, 4] and count % 100 not in [12, 13, 14] else "punktów cech")
		_expect(tr_n("★ %d STAT POINT", "★ %d STAT POINTS", count) % count, "★ %d %s" % [count, form], "Polish plural %d" % count)
	var panel := SettingsPanel.new()
	root.add_child(panel)
	panel.build(GamePreferences.RESOLUTIONS, 0, false, 0.25, GamePreferences.ACTIONS)
	_check(panel.language_picker.selected == 1, "Polish picker selection")
	_check(ThemeDB.fallback_font.has_char("ą".unicode_at(0)) and ThemeDB.fallback_font.has_char("Ł".unicode_at(0)), "Polish glyph coverage")
	_check(GamePreferences.binding_text("move_up", "keyboard").contains("↑"), "direction binding glyph")
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_X
	_expect(InputBindingNames.describe(button), "X / □", "Square controller identity")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	key.ctrl_pressed = true
	_expect(InputBindingNames.describe(key), "Ctrl+J", "modified binding caption")
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.ctrl_pressed = true
	_expect(InputBindingNames.describe(mouse), "Ctrl+Lewy przycisk myszy", "modified mouse caption")
	var label := Label.new()
	label.text = "New adventure   →"
	root.add_child(label)
	var reference := Label.new()
	reference.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	reference.text = "Nowa przygoda   →"
	root.add_child(reference)
	var sign := Label3D.new()
	sign.text = "GODFUFU\nKing of the Cloud Realm"
	root.add_child(sign)
	var sign_reference := Label3D.new()
	sign_reference.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	sign_reference.text = "GODFUFU\nKról Chmurokrólestwa"
	root.add_child(sign_reference)
	var map := MapCanvas.new()
	root.add_child(map)
	_expect(map._caption({"label": "Apple", "kind": "player", "local": false}), "Apple", "player map name")
	_expect(map._caption({"label": "Cloud Realm · Godfufu", "kind": "npc"}), "Chmurokrólestwo · Godfufu", "map location")
	map.free()
	var bubble := SpeechBubble.new()
	bubble.text = "Apple · New adventure   →"
	root.add_child(bubble)
	_check(not bubble.can_auto_translate(), "speech bubble preserves player text")
	await process_frame
	_check(label.get_minimum_size().is_equal_approx(reference.get_minimum_size()), "automatic Control translation")
	_check(sign.get_aabb().size.is_equal_approx(sign_reference.get_aabb().size), "automatic world sign translation")
	TranslationServer.set_locale("en")
	await process_frame
	_expect(tr("Bought Knife for 3 Mature Beans. Equipped immediately."), "Bought Knife for 3 Mature Beans. Equipped immediately.", "English fallback")
	_check(not label.get_minimum_size().is_equal_approx(reference.get_minimum_size()), "live Control language switching")
	_check(not sign.get_aabb().size.is_equal_approx(sign_reference.get_aabb().size), "live world sign language switching")
	var preferences := GamePreferences.new()
	preferences.path = "user://localization-test.cfg"
	preferences.apply_language("pl")
	_check(preferences.save() == OK, "language persistence")
	var restored := GamePreferences.new()
	restored.path = preferences.path
	restored.load_preferences()
	_check(restored.language == "pl" and TranslationServer.get_locale() == "pl", "restored locale")
	restored.apply_language("untrusted-locale")
	_check(restored.language == "en", "unsupported locale fallback")
	DirAccess.remove_absolute(preferences.path)
	panel.queue_free()
	label.queue_free()
	reference.queue_free()
	sign.queue_free()
	sign_reference.queue_free()
	bubble.queue_free()
	await process_frame
	for failure in failures: push_error("FAIL: " + failure)
	print("Localization: %s" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func _expect(actual: String, expected: String, context: String) -> void:
	_check(actual == expected, "%s: expected %s, got %s" % [context, expected, actual])

func _check(condition: bool, context: String) -> void:
	if not condition: failures.append(context)

func _check_templates() -> void:
	var translation := preload("res://game/settings/localization/pl.tres")
	var token := RegEx.create_from_string("%[-+0-9.]*[dsf]|%%")
	var checked := 0
	for source in translation.catalog.get_message_list():
		var fields := token.search_all(source)
		if fields.is_empty() or source in ["★ %d STAT POINT", "%s %s", "[%s] %s %s", "Are you sure you want to drop %s%s onto the ground?"]: continue
		var values: Array = []
		var translated_values: Array = []
		var opaque: Array = LocalizedMessages.OPAQUE.get(source, [])
		for field in fields:
			if field.get_string() == "%%": continue
			var value: Variant = 17 if field.get_string().ends_with("d") else (1.25 if field.get_string().ends_with("f") else "Knife")
			translated_values.append("Nożyk" if value is String and values.size() not in opaque else value)
			values.append(value)
		if values.is_empty(): continue
		var original := _sample(source, values, token)
		var expected := _sample(translation.catalog.get_message(source), translated_values, token)
		_expect(tr(original), expected, "template " + source)
		checked += 1
	_check(checked > 150, "formatted catalog coverage")
	print("Formatted localization templates checked: ", checked)

func _sample(template: String, values: Array, token: RegEx) -> String:
	var result := ""
	var cursor := 0
	var index := 0
	for field in token.search_all(template):
		result += template.substr(cursor, field.get_start() - cursor)
		if field.get_string() == "%%": result += "%"
		else:
			result += field.get_string() % values[index]
			index += 1
		cursor = field.get_end()
	return result + template.substr(cursor)

func _check_items() -> void:
	var ids := ["edamame", "mature_bean", "tofu_white_chunk", "toasted_tofu_chunk", "golden_tofu_chunk", "knife", "soy_gun", "sotjet", "sproutwood_staff", "edamame_sword", "nori_katana", "factory_backpack", "seed_satchel", "traveler_backpack", "piece_of_shell", "soy_milk", "apple", "magical_tofufu_chunk", "potato", "cucumber", "red_berries", "beetroot", "forest_mushroom"]
	ids.append_array(CelestialItems.IDS)
	for prefix in ["bright_leaf_", "dark_leaf_"]:
		for slot in ["helmet", "armor", "legs", "boots"]: ids.append(prefix + slot)
	for id: String in ids:
		var item := InventoryItem.from_id(id)
		_check(item != null and item.id == id, "item identity " + id)
		if item == null: continue
		_check(tr(item.name) != item.name or id == "edamame", "item name coverage " + id)
		_check(tr(item.description) != item.description, "item description coverage " + id)
	print("Localized item definitions checked: ", ids.size())

func _check_character_copy() -> void:
	_expect(tr("MY TOFUFU"), "MÓJ TOFUFU", "character hub heading")
	_expect(tr("Trailblazer"), "Odkrywca szlaków", "walking mastery")
	_expect(tr("Flowkeeper"), "Mistrz rytmu", "combat mastery")
	_expect(tr("Tenderheart"), "Troskliwe serce", "care mastery")
	_expect(tr("Held: Knife · Enhanced"), "W ręku: Nożyk · Wzmocniona", "nested equipment summary")
	_expect(tr("Knife · 1.5% protection"), "Nożyk · 1.5% ochrony", "numeric equipment bonus")
	_expect(tr("Trailblazer 2 / A little stronger through the life you share."), "Odkrywca szlaków 2 / Wspólne życie dodaje ci siły.", "mastery notification")
	_expect(tr("Recovering after combat · 23s until HP regeneration"), "Odpoczynek po walce · 23s do regeneracji HP", "recovery condition")
	for count in [1, 2, 5, 12, 22]:
		var form: String = "punkt" if count == 1 else ("punkty" if count % 10 in [2, 3, 4] and count % 100 not in [12, 13, 14] else "punktów")
		_expect(tr_n("%d point to invest", "%d points to invest", count) % count, "%d %s do rozdania" % [count, form], "character investment plurals")
