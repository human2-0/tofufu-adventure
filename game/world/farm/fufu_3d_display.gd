class_name Fufu3DDisplay
extends Node3D
## Cosmetic village study of Fufu: the reusable GLB owns its authored walk cycle.

@export var walking: bool = true
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
const PAINTED_MARKS := ["Eyes", "EyeGlints", "PeachCheeks", "GoldenFreckles", "BrowsAndSmile", "BackFreckles", "RightFingerInk", "LeftFingerInk"]

func _ready() -> void:
	for clip in ["Walk", "Idle"]:
		animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation.play("Walk" if walking else "Idle")
	_limit_visibility($Model)

func _limit_visibility(parent: Node) -> void:
	for child in parent.get_children():
		if child is GeometryInstance3D:
			child.visibility_range_end = 48.0
			child.visibility_range_end_margin = 4.0
			if str(child.name) in PAINTED_MARKS:
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_limit_visibility(child)
