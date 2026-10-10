class_name RenderBudget
extends Node
## Local viewport adaptation; no gameplay, authority or network state changes.

var preferences: GamePreferences
var is_playing: Callable
var policy := ResolutionBudget.new()
var _cap: int = -1
var _ceiling: float = -1.0
var _automatic: bool = false
var _last_usec: int = 0

static func install(parent: Node, settings: GamePreferences, active: Callable) -> void:
	settings.apply_rendering(parent.get_viewport(), settings.frame_limit, settings.render_scale, settings.vsync)
	var budget := RenderBudget.new()
	budget.preferences = settings
	budget.is_playing = active
	parent.add_child(budget)

func _ready() -> void:
	_last_usec = Time.get_ticks_usec()
	if DisplayServer.get_name() == "headless": set_process(false)

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var seconds := (now - _last_usec) / 1000000.0
	_last_usec = now
	var changed := _cap != preferences.frame_limit or _ceiling != preferences.render_scale or _automatic != preferences.adaptive_resolution
	if changed:
		_cap = preferences.frame_limit
		_ceiling = preferences.render_scale
		_automatic = preferences.adaptive_resolution
		policy.reset(_cap, _ceiling)
		get_viewport().scaling_3d_scale = _ceiling
	if not is_playing.call() or not _automatic or _cap == 0: return
	var scale := policy.sample(seconds)
	if not is_equal_approx(get_viewport().scaling_3d_scale, scale): get_viewport().scaling_3d_scale = scale
