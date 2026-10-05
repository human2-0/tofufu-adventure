extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var map := MapExploration.new()
	check(not map.visited(Vector2.ZERO), "new map starts undiscovered")
	check(map.reveal(Vector2.ZERO), "first visit changes mask")
	check(map.visited(Vector2(5, 0)) and not map.visited(Vector2(15, 0)), "reveal is a small radius")
	var origin_cell := Vector2i((Vector2.ZERO - MapExploration.BOUNDS.position) / 2)
	check(map.mask_image().get_pixelv(origin_cell).r == 1, "cached visual mask follows newly discovered cells")
	check(not map.reveal(Vector2.ZERO), "stationary player does not rebuild mask")
	map.reveal(Vector2(80, 80))
	check(map.visited(Vector2.ZERO) and not map.visited(Vector2(40, 40)), "teleport preserves history without revealing intervening terrain")
	var other := MapExploration.new()
	check(not other.visited(Vector2.ZERO), "players have independent exploration")
	other.restore(map.capture())
	check(other.visited(Vector2.ZERO) and other.visited(Vector2(80, 80)), "mask round trip")
	check(not map.reveal(Vector2(1000, 1000)), "out-of-world positions ignored")
	map.reveal(MapExploration.BOUNDS.position + Vector2.ONE)
	check(map.visited(MapExploration.BOUNDS.position + Vector2.ONE), "edge discovery is bounded")
	other.restore("invalid")
	check(not other.visited(Vector2.ZERO), "invalid or legacy state starts unknown")
	check(other.mask_image().get_pixelv(origin_cell).r == 0, "restoring invalid state clears the cached fog pixels")
	other.restore("!".repeat(10120))
	check(not other.visited(Vector2.ZERO), "malformed base64 is ignored safely")
	print("Map exploration: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
