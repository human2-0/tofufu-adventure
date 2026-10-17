class_name UpdateLogPanel
extends VBoxContainer
## Explicit bilingual copy stays bilingual regardless of the selected UI locale.

signal closed
var close_button: Button

func build(entries: Array[Dictionary]) -> void:
	add_theme_constant_override("separation", 16)
	close_button = MenuStyle.button(self, "Back to menu", closed.emit, MenuIcons.ARROW)
	MenuStyle.focus_later(close_button)
	for index in range(entries.size() - 1, -1, -1):
		var entry := entries[index]
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 8)
		add_child(section)
		MenuStyle.label(section, String(entry.date), 14, MenuStyle.SOY_GOLD)
		MenuStyle.label(section, String(entry.title), 22)
		_bullets(section, entry.bullets, "English", "en")
		_bullets(section, entry.bullets, "Polski", "pl")

func _bullets(parent: Node, bullets: Array, caption: String, locale: String) -> void:
	var label := MenuStyle.label(parent, caption, 16, MenuStyle.MINT)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var lines := PackedStringArray()
	for source: String in bullets:
		var text := source if locale == "en" else _polish(source)
		lines.append("• " + text)
	label = MenuStyle.paragraph(parent, "\n".join(lines))
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED

func _polish(source: String) -> String:
	var catalog := preload("res://game/settings/localization/pl.po")
	return String(catalog.get_message(source))
