class_name GraphicsPreferences
extends RefCounted
## Device-local cosmetic switches. Weather rules and movement remain authoritative.

signal changed
const LABELS: Dictionary[String, String] = {
	"wind": "Wind animation and leaves", "rain": "Rain particles", "snow": "Snow particles",
	"lightning": "Lightning flashes", "thunder": "Thunder sounds", "puddles": "Puddles and rain splashes",
	"motes": "Fireflies and movement particles", "fog": "Atmospheric fog", "audio": "Wind and rain sounds"
}
var values: Dictionary[String, bool] = {}

func enabled(key: String) -> bool:
	return values.get(key, true)

func set_enabled(key: String, value: bool) -> void:
	if not LABELS.has(key) or enabled(key) == value: return
	values[key] = value
	changed.emit()

func load_config(config: ConfigFile) -> void:
	for key: String in LABELS:
		var value: Variant = config.get_value("effects", key, true)
		values[key] = value if value is bool else true

func save_config(config: ConfigFile) -> void:
	for key: String in LABELS: config.set_value("effects", key, enabled(key))
