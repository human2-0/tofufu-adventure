class_name HonioVisuals
extends Sprite3D
## Forty authored poses; torso/foot registration prevents side-to-side atlas drift.
const SHEETS: Dictionary = {
	"idle": "res://assets/characters/honio_meniono/idle.png",
	"run": "res://assets/characters/honio_meniono/run.png",
	"melee": "res://assets/characters/honio_meniono/melee.png"
}
var frames: Array[AtlasTexture] = []
var layout: Array = []
var direction_index: int = 0
var pose: int = 0
var elapsed: float = 0

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	alpha_scissor_threshold = 0.15
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var metadata := load("res://assets/characters/honio_meniono/sprite-layout.json") as JSON
	layout = metadata.data.frames
	for data: Dictionary in layout:
		var frame := AtlasTexture.new()
		frame.atlas = load(SHEETS[data.sheet]) as Texture2D
		frame.region = Rect2(data.region[0], data.region[1], data.region[2], data.region[3])
		frame.filter_clip = true
		frames.append(frame)
	present(Vector3.BACK, false, 0, 0, 0, 0)

func present(facing: Vector3, moving: bool, phase: int, skill: int, impact: float, delta: float) -> void:
	elapsed += delta
	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.BACK if camera == null else camera.global_basis.z
	forward.y = 0
	forward = forward.normalized()
	var right := Vector3(forward.z, 0, -forward.x)
	direction_index = posmod(roundi(atan2(-facing.dot(right), facing.dot(forward)) / (PI / 4)), 8)
	pose = 1 + int(elapsed * 11) % 2 if moving else 0
	if phase in [HonioMelee.Phase.WARNING, HonioMelee.Phase.RUSH] or impact > 0:
		pose = 4 if skill == HonioMelee.Skill.TOFU_TENDERIZER else 3
	var index := pose * 8 + direction_index
	var data: Dictionary = layout[index]
	texture = frames[index]
	pixel_size = data.pixel_size
	offset.x = data.region[2] * 0.5 - data.center
	position.y = (data.foot - data.region[3] * 0.5) * pixel_size + 0.03
	modulate = modulate.lerp(Color.WHITE, minf(1, delta * 9))
