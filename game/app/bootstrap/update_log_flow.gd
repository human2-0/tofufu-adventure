class_name UpdateLogFlow
extends RefCounted
## Device-local acknowledgement; independent of adventure saves and peers.

var menu: LaunchMenu
var go_back: Callable
var path: String = "user://updates.cfg"
var seen: int = 0
var panel: UpdateLogPanel
var _shown_through: int = 0

func load_seen() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK: return
	var value: Variant = config.get_value("updates", "seen", 0)
	seen = maxi(0, value) if value is int else 0

func show_unseen() -> void:
	if not UpdateLog.since(seen).is_empty(): _show(UpdateLog.since(seen))

func show_history() -> void:
	_show(UpdateLog.ENTRIES)

func _show(entries: Array[Dictionary]) -> void:
	var content := menu.clear_page("What's new?", "A little catch-up before your next adventure. English + Polski.", true)
	menu.set_page_width(820)
	menu.note.text = ""
	panel = UpdateLogPanel.new()
	content.add_child(panel)
	panel.build(entries)
	_shown_through = UpdateLog.latest_id()
	panel.closed.connect(_close)

func _close() -> void:
	var config := ConfigFile.new()
	config.set_value("updates", "seen", maxi(seen, _shown_through))
	if config.save(path) != OK:
		go_back.call()
		menu.note.text = "Could not remember read updates. They will appear again next time."
		return
	seen = maxi(seen, _shown_through)
	go_back.call()
