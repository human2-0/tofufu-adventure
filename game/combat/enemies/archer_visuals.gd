class_name ArcherVisuals
extends Sprite3D
## Four authored directions and draw poses, selected relative to the camera.

const REGIONS: Array[Rect2] = [
	Rect2(38, 32, 405, 345), Rect2(505, 32, 382, 345),
	Rect2(1050, 32, 390, 345), Rect2(1545, 32, 410, 345),
	Rect2(32, 400, 433, 360), Rect2(468, 400, 457, 360),
	Rect2(1035, 400, 473, 360), Rect2(1510, 400, 445, 360),
]
var elapsed: float = 0.0

func _ready() -> void:
	texture = load("res://assets/characters/groatfields/archer.png")
	region_enabled = true
	region_rect = REGIONS[0]
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pixel_size = 2.8 / (texture.get_height() / 2.0)
	position.y = 1.35

func present(facing: Vector3, windup: float, delta: float) -> void:
	elapsed += delta
	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.BACK if camera == null else camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var dot := facing.dot(forward)
	var column := 0 if dot > 0.55 else (1 if dot < -0.55 else (3 if facing.dot(forward.cross(Vector3.UP)) > 0 else 2))
	region_rect = REGIONS[column + (4 if windup > 0 else 0)]
	position.y = 1.35 + sin(elapsed * 3) * 0.04
	modulate = modulate.lerp(Color.WHITE, minf(1, delta * 8))
