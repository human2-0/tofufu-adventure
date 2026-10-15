class_name LocalizedMessages
extends Translation
## Presentation adapter for authored English messages already composed by rules/peers.
## Gameplay, saves and packets retain their original identifiers and source text.

@export var catalog: Translation
var _messages: Dictionary[String, String] = {}
var _patterns: Array[Dictionary] = []
var _fragments: Array[String] = []
var _cache: Dictionary[StringName, StringName] = {}
var _prepared: bool = false
var _slots := RegEx.create_from_string("\\{([0-9]+)\\}")
const OPAQUE := {
	"Playing as %s": [0], "Welcome back, %s": [0], "Continue · %s": [0],
	"Adventure saved · %s": [0], "Adventure saved / %s": [0],
	"%s\n%s  ·  %d min  ·  %d EXP": [0], "Connecting to %s…": [0],
	"%s SCORES / %s / 5": [0], "%s SURRENDERED / %s WINS": [0, 1],
	"%s WINS THE DUEL! FIRST TO 10.": [0], "DUEL / %s VS %s / CHOOSE YOUR LOADOUT": [0, 1],
	"DUEL · %s %d - %d %s · %s": [0, 3], "WINNER: %s": [0], "%s: %s · %s": [0],
}

func _get_message(source: StringName, _context: StringName) -> StringName:
	if not _prepared: _prepare()
	if _cache.has(source): return _cache[source]
	var translated := _text(String(source), 0)
	var result := StringName(translated) if translated != String(source) else &""
	if _cache.size() >= 2048: _cache.clear()
	_cache[source] = result
	return result

func _get_plural_message(source: StringName, plural: StringName, count: int, context: StringName) -> StringName:
	return catalog.get_plural_message(source, plural, count, context)

func _prepare() -> void:
	_prepared = true
	var token := RegEx.create_from_string("%[-+0-9.]*[dsf]|%%")
	for key in catalog.get_message_list():
		var target := String(catalog.get_message(key))
		_messages[key] = target
		var source_lines := key.split("\n")
		var target_lines := target.split("\n")
		if source_lines.size() == target_lines.size():
			for index in source_lines.size():
				if not source_lines[index].is_empty(): _messages[source_lines[index]] = target_lines[index]
	for key: String in _messages:
		if key in ["%s", "%s %s", "%s · %s", "[%s] %s %s"]: continue
		var matches := token.search_all(key)
		if matches.is_empty():
			if key != key.strip_edges() and not key.strip_edges().is_empty(): _fragments.append(key)
			continue
		_add_pattern(key, _messages[key], matches, token)
	_patterns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.weight > b.weight)
	_fragments.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())

func _add_pattern(key: String, target: String, matches: Array[RegExMatch], token: RegEx) -> void:
	var expression := "(?s)^"
	var cursor := 0
	var count := 0
	var weight := key.length()
	for found in matches:
		expression += _escape(key.substr(cursor, found.get_start() - cursor))
		var field := found.get_string()
		if field == "%%": expression += "%"
		else:
			expression += "(-?[0-9]+)" if field.ends_with("d") else ("(-?[0-9]+(?:\\.[0-9]+)?)" if field.ends_with("f") else "([^\\n]*?)")
			count += 1
			weight -= field.length() + 4
		cursor = found.get_end()
	expression += _escape(key.substr(cursor)) + "$"
	if count == 0: return
	var placeholders := token.search_all(target)
	for index in range(placeholders.size() - 1, -1, -1):
		var field := placeholders[index]
		var replacement := "%" if field.get_string() == "%%" else "{%d}" % _field_index(placeholders, index)
		target = target.substr(0, field.get_start()) + replacement + target.substr(field.get_end())
	_patterns.append({"regex": RegEx.create_from_string(expression), "target": target, "opaque": OPAQUE.get(key, []), "weight": weight})

func _field_index(fields: Array[RegExMatch], until: int) -> int:
	var result := 0
	for index in until:
		if fields[index].get_string() != "%%": result += 1
	return result

func _escape(value: String) -> String:
	var result := ""
	for character in value:
		if character in "\\.^$|?*+()[]{}": result += "\\"
		result += character
	return result

func _text(source: String, depth: int) -> String:
	if source.is_empty() or depth > 6: return source
	if _messages.has(source): return _messages[source]
	for pattern in _patterns:
		var found: RegExMatch = pattern.regex.search(source)
		if found == null: continue
		var values: PackedStringArray = []
		for index in found.get_group_count():
			var value := found.get_string(index + 1)
			if index not in pattern.opaque and value != source: value = _text(value, depth + 1)
			values.append(value)
		return _substitute(pattern.target, values)
	for fragment in _fragments:
		if source.begins_with(fragment): return _messages[fragment] + _text(source.trim_prefix(fragment), depth + 1)
		if source.ends_with(fragment): return _text(source.trim_suffix(fragment), depth + 1) + _messages[fragment]
	for separator: String in ["\n", " · ", " / ", " • "]:
		if not source.contains(separator): continue
		var parts := source.split(separator)
		for index in parts.size(): parts[index] = _text(parts[index], depth + 1)
		var result: String = separator.join(parts)
		if result != source: return result
	return source

func _substitute(target: String, values: PackedStringArray) -> String:
	var result := ""
	var cursor := 0
	for slot in _slots.search_all(target):
		result += target.substr(cursor, slot.get_start() - cursor)
		result += values[int(slot.get_string(1))]
		cursor = slot.get_end()
	return result + target.substr(cursor)
