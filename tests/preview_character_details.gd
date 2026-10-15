extends SceneTree
## Native screenshots of the actual hub, equipment tradeoffs and compact scroll.
const OUT := "res://.codex/visualizations/2026/10/15/character-details/"
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var game: AdventureGame = preload("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	await physics_frame
	game.progression.progress.award_experience(CharacterProgress.threshold(20, true))
	game.progression.progress.record_journey("trail", 1750)
	game.progression.progress.record_journey("rhythm", 240)
	game.progression.progress.record_journey("care", 600)
	for slot in CharacterEquipment.APPAREL_SLOTS: game.character_equipment.set_slot(slot, ItemStack.new(InventoryItem.apparel("dark_leaf_" + slot)))
	var sword := ItemStack.new(InventoryItem.weapon("nori_katana"))
	sword.enhanced = true
	game.character_equipment.set_slot("combat_1", sword)
	await create_timer(5.5).timeout
	game.inventory_window.open()
	for locale in ["en", "pl"]:
		TranslationServer.set_locale(locale)
		root.content_scale_size = Vector2i(1280, 720)
		root.size = Vector2i(1280, 720)
		game.inventory_window.character_requested.emit()
		for child in game.inventory_window.get_children():
			if child is CharacterSheet: _reset_scroll(child)
		await _capture(locale + "-normal")
		root.content_scale_size = Vector2i(960, 540)
		root.size = Vector2i(960, 540)
		await _capture(locale + "-compact")
		for child in game.inventory_window.get_children():
			if child is CharacterSheet: child.skills.defence.button.grab_focus()
		await _capture(locale + "-controller-scroll")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	for slot in CharacterEquipment.APPAREL_SLOTS: game.character_equipment.set_slot(slot, ItemStack.new(InventoryItem.apparel("bright_leaf_" + slot)))
	await create_timer(5.5).timeout
	await _capture("pl-tradeoffs")
	print("Character previews: ", ProjectSettings.globalize_path(OUT))
	quit()
func _capture(label: String) -> void:
	for frame in 15: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")

func _reset_scroll(node: Node) -> void:
	if node is ScrollContainer: node.scroll_vertical = 0
	for child in node.get_children(): _reset_scroll(child)
