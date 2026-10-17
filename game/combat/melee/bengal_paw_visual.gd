class_name BengalPawVisual
extends Sprite3D
## Painted glove cutout shared by world-worn and camera-space paws.

const ART: Texture2D = preload("res://assets/weapons/bengal_paws/glove-worn.png")
const WRIST := Vector2(0.5, 0.89)

func _ready() -> void:
	texture = ART
	shaded = false
	pixel_size = 0.36 / ART.get_height()
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func wear(wrist: Vector3, plane: Basis, span: float = 0.29) -> void:
	# Bind the fitted cuff to the wrist, rather than centering a loose item on it.
	pixel_size = span / ART.get_height()
	var anchor := Vector3((WRIST.x - 0.5) * ART.get_width(), (0.5 - WRIST.y) * ART.get_height(), 0) * pixel_size
	global_transform = Transform3D(plane, wrist - plane * anchor)
