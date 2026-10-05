class_name AppleDropVisual
extends Node3D
## Fallen fruit stays visibly grounded until an explicit pickup removes its stack.

var drop: WorldItemDrop
var _apples: Array[Node3D] = []
var _shown_count: int = -1

func _ready() -> void:
	drop.ring.position.y = -WorldItemDrop.RADIUS + 0.025
	for index in AppleTree.APPLE_YIELD:
		var apple := AppleTreeVisuals.create_apple_model()
		apple.scale = Vector3.ONE * 1.3
		apple.position = Vector3((index % 2) * 0.36 - 0.18, -WorldItemDrop.RADIUS + 0.052, (index / 2) * 0.36 - 0.18)
		apple.rotation.y = index * 1.7
		add_child(apple)
		_apples.append(apple)
	_update_count()

func _process(_delta: float) -> void:
	if drop.count != _shown_count: _update_count()

func _update_count() -> void:
	_shown_count = drop.count
	for index in _apples.size():
		_apples[index].visible = index < _shown_count
