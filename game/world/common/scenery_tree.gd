@tool
extends StaticBody3D
## Presentation of the reusable tree scene; authored collision volumes stay fixed.

func _ready() -> void:
	NaturalTreeVisuals.build(self)
