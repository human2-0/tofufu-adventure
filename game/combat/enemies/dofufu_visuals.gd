class_name DofufuVisuals
extends Sprite3D
## Eight-way authored art with calibrated isolated regions and foot baselines.

const ATLAS := preload("res://assets/characters/dofufu/dofufu-directions.png")
const REGIONS: Array[Rect2] = [
	Rect2(47, 49, 215, 272), Rect2(371, 49, 232, 272),
	Rect2(705, 49, 192, 272), Rect2(1010, 49, 206, 272),
	Rect2(49, 349, 221, 268), Rect2(355, 349, 232, 268),
	Rect2(686, 349, 195, 268), Rect2(980, 349, 233, 268),
	Rect2(16, 649, 288, 252), Rect2(329, 649, 306, 252),
	Rect2(638, 649, 295, 252), Rect2(950, 649, 287, 252),
	Rect2(11, 939, 299, 252), Rect2(327, 939, 295, 252),
	Rect2(626, 939, 328, 252), Rect2(959, 939, 280, 252),
]
const CENTERS: Array[float] = [154, 474, 793, 1109, 155, 475, 791, 1110, 165, 480, 794, 1111, 166, 482, 792, 1110]
const FEET: Array[float] = [268, 269, 270, 268, 264, 266, 266, 266, 246, 242, 247, 250, 241, 244, 246, 250]
var elapsed: float = 0.0
var direction_index: int = 0
var pose_index: int = 0
var frames: Array[AtlasTexture] = []

func _ready() -> void:
	for region in REGIONS:
		var cell := AtlasTexture.new()
		cell.atlas = ATLAS
		cell.region = region
		cell.filter_clip = true
		frames.append(cell)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pixel_size = 2.5 / 268.0
	position.y = 1.25
	set_pose(0)

func set_pose(index: int) -> void:
	pose_index = clampi(index, 0, 15)
	texture = frames[pose_index]
	var region := REGIONS[pose_index]
	offset.x = region.size.x * 0.5 - (CENTERS[pose_index] - region.position.x)
	offset.y = FEET[pose_index] - region.size.y * 0.5 - 1.25 / pixel_size

func present(facing: Vector3, moving: bool, attacking: bool, enraged: bool, delta: float) -> void:
	elapsed += delta
	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.BACK if camera == null else camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	var angle := atan2(facing.dot(right), facing.dot(forward))
	# Positive camera-right turns S -> SE; Fufu's atlas advances S -> SW.
	direction_index = posmod(-roundi(angle / (PI / 4.0)), 8)
	set_pose(direction_index + (8 if attacking or moving else 0))
	position.y = 1.25 + (absf(sin(elapsed * 10.0)) * 0.06 if moving else sin(elapsed * 2.0) * 0.025)
	modulate = Color("ffbd87") if enraged else Color.WHITE
