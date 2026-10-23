class_name GraphicsPreferences
extends RefCounted
## Device-local cosmetic switches. Weather rules and movement remain authoritative.

signal changed
const RENDER_SCALES: Array[float] = [0.5, 0.65, 0.75, 0.85, 1.0]
const SCENERY_DISTANCES: Array[int] = [160, 240, 360, 0]
var scenery_distance: int = 240
var shadows: bool = true
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
	var distance: Variant = config.get_value("royale_graphics", "distance", 240)
	scenery_distance = int(distance) if distance is int and distance in SCENERY_DISTANCES else 240
	var shade: Variant = config.get_value("royale_graphics", "shadows", true)
	shadows = shade if shade is bool else true
	for key: String in LABELS:
		var value: Variant = config.get_value("effects", key, true)
		values[key] = value if value is bool else true

func save_config(config: ConfigFile) -> void:
	config.set_value("royale_graphics", "distance", scenery_distance)
	config.set_value("royale_graphics", "shadows", shadows)
	for key: String in LABELS: config.set_value("effects", key, enabled(key))

func set_scenery(distance: int, cast_shadows: bool) -> void:
	if distance not in SCENERY_DISTANCES: return
	scenery_distance = distance
	shadows = cast_shadows
	changed.emit()

func use_performance_preset() -> void:
	scenery_distance = 160
	shadows = false
	for key in ["wind", "motes", "puddles"]: values[key] = false
	changed.emit()
