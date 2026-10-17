class_name PunchImpact
extends Sprite3D
## Short, camera-facing strike cutouts; sequence and outfit come from the actor.

const ART: Texture2D = preload("res://assets/combat/fufu_strikes/strikes.png")
const OUTFITS: Array[String] = ["", "bright_leaf", "dark_leaf", "celestial"]
const STYLES: Array[String] = ["jab", "cross", "uppercut", "kick"]
const LIFETIME: float = 0.16
const ROW_EDGES: Array[int] = [0, 314, 627, 924, 1254]
const PAINTED_ANGLES: Array[float] = [PI / 4.0, PI * 0.75, PI / 2.0, PI / 4.0]
var style: int = 0
var outfit: String = ""
var forward := Vector3.BACK
var speed: float = 1.0
var age: float = 0.0
var origin := Vector3.ZERO

static func variant(sequence: int) -> int:
	return posmod(sequence - 1, STYLES.size())

static func spawn(parent: Node, at: Vector3, sequence: int, set_id: String, aim: Vector2, pace: float) -> PunchImpact:
	for previous in parent.get_children():
		if previous is PunchImpact and not previous.is_queued_for_deletion():
			previous.age = maxf(previous.age, LIFETIME * 0.72)
			previous.present()
	var effect := PunchImpact.new()
	effect.style = variant(sequence)
	effect.outfit = set_id if set_id in OUTFITS else ""
	var direction := aim.normalized() if not aim.is_zero_approx() else Vector2.DOWN
	effect.forward = Vector3(direction.x, 0, direction.y)
	effect.speed = clampf(pace, 0.1, 10.0)
	effect.origin = at
	parent.add_child(effect)
	effect.present()
	return effect

func _ready() -> void:
	top_level = true
	var row := OUTFITS.find(outfit)
	var start := Vector2(roundf(style * ART.get_width() / 4.0), ROW_EDGES[row])
	var end := Vector2(roundf((style + 1) * ART.get_width() / 4.0), ROW_EDGES[row + 1])
	var view := AtlasTexture.new()
	view.atlas = ART
	view.region = Rect2(start, end - start)
	view.filter_clip = true
	texture = view
	pixel_size = (0.85 if style == 3 else 0.72) / (ART.get_height() / 4.0)
	shaded = false
	double_sided = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_range_end = 48.0
	visibility_range_end_margin = 2.0
	present()

func _process(delta: float) -> void:
	age += delta * speed
	if age >= LIFETIME:
		queue_free()
		return
	present()

func present() -> void:
	var progress := clampf(age / LIFETIME, 0.0, 1.0)
	var camera := get_viewport().get_camera_3d()
	var plane := camera.global_basis.orthonormalized() if camera != null else Basis.IDENTITY
	var projected := Vector2(forward.dot(plane.x), forward.dot(plane.y))
	var roll := projected.angle() - PAINTED_ANGLES[style] if projected.length_squared() > 0.01 else 0.0
	var curve := sin(progress * PI)
	var side: float = [-0.07, 0.07, 0.0, 0.02][style]
	var lift := curve * 0.16 if style == 2 else (-0.18 if style == 3 else 0.0)
	global_position = origin + forward * lerpf(-0.08, 0.10, smoothstep(0.0, 0.45, progress)) + plane.x * side + Vector3.UP * lift
	var size := lerpf(0.78, 1.08, smoothstep(0.0, 0.35, progress))
	global_basis = (plane * Basis(Vector3.BACK, roll)).scaled(Vector3.ONE * size)
	modulate.a = 1.0 - smoothstep(0.48, 1.0, progress)
