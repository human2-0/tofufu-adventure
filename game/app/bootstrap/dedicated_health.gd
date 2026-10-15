class_name DedicatedHealth
extends Node
## Writes a small operational heartbeat without exposing identities or credentials.

var server: DedicatedServer
var _clock: float = 0

func _process(delta: float) -> void:
	_clock += delta
	if _clock < 5: return
	_clock = 0
	var data := {"updated_at": Time.get_unix_time_from_system(), "players": server.room.members.size(), "capacity": 4,
		"tick_hz": server.session.connection_health.tick_hz, "saved_at": server.last_saved_at,
		"memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC)}
	var path := server.state_directory.path_join("health.json")
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify(data))
	file.close()
	DirAccess.rename_absolute(path + ".tmp", path)
