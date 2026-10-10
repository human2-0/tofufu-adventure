class_name MobVisibility
extends RefCounted
## Render visibility gates only cosmetic pose updates, including on guest replicas.

var _notifier: VisibleOnScreenNotifier3D
var _elapsed: float = 0.0

func build(actor: Node3D) -> void:
	_notifier = VisibleOnScreenNotifier3D.new()
	_notifier.aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 6, 6))
	actor.add_child(_notifier)

func render_delta(delta: float) -> float:
	if DisplayServer.get_name() == "headless": return delta
	_elapsed = minf(0.5, _elapsed + delta)
	if not _notifier.is_on_screen(): return 0.0
	var elapsed := _elapsed
	_elapsed = 0.0
	return elapsed
