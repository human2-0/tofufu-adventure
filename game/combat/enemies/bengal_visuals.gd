class_name BengalVisuals
extends Sprite3D
## Five painted views, mirrored to eight facings, with isolated running/claw poses.

const SHEET: Texture2D = preload("res://assets/characters/bengal/bengal-directions.png")
const REGIONS: Array[Rect2] = [
	Rect2(15,34,239,254), Rect2(289,35,241,250), Rect2(572,40,296,246), Rect2(895,35,229,253), Rect2(1186,36,203,251),
	Rect2(28,299,211,257), Rect2(265,330,288,219), Rect2(560,335,323,201), Rect2(902,342,280,216), Rect2(1227,324,141,238),
	Rect2(36,566,213,257), Rect2(289,588,274,231), Rect2(570,594,322,234), Rect2(930,605,221,217), Rect2(1221,582,140,249),
	Rect2(22,830,237,257), Rect2(272,841,290,243), Rect2(558,842,336,236), Rect2(887,853,301,232), Rect2(1191,848,201,231),
]
const CENTERS: Array[float] = [162, 425, 728, 1026, 1290, 144, 419, 722, 1040, 1300, 144, 427, 731, 1038, 1296, 153, 426, 732, 1040, 1298]
const VIEWS: Array[int] = [0, 1, 2, 3, 4, 3, 2, 1]
var direction_index: int = 0
var pose_row: int = 0
var elapsed: float = 0
var _frames: Array[AtlasTexture] = []

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pixel_size = 1.45 / 244.0
	for region in REGIONS:
		var atlas_frame := AtlasTexture.new()
		atlas_frame.atlas = SHEET
		atlas_frame.region = region
		atlas_frame.filter_clip = true
		_frames.append(atlas_frame)
	present(Vector3.BACK, false, 0, 0, 0)

func present(facing: Vector3, running: bool, windup: float, claw: float, delta: float) -> void:
	elapsed += delta
	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.BACK if camera == null else camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	direction_index = posmod(roundi(atan2(facing.dot(right), facing.dot(forward)) / (PI / 4)), 8)
	pose_row = 3 if claw > 0 else (1 + int(elapsed * 10) % 2 if running else 0)
	var index := pose_row * 5 + VIEWS[direction_index]
	var region := REGIONS[index]
	texture = _frames[index]
	flip_h = direction_index > 4
	offset.x = (region.size.x * 0.5 - (CENTERS[index] - region.position.x)) * (-1 if flip_h else 1)
	position.y = (region.size.y * 0.5 - 5) * pixel_size + 0.04
	rotation.z = sin(elapsed * 22) * 0.035 if running else (sin(elapsed * 35) * 0.045 if windup > 0 else 0.0)
	modulate = modulate.lerp(Color.WHITE, minf(1, delta * 8))
