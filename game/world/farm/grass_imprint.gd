class_name GrassImprint
extends RefCounted
## Sparse recovering bends in a fixed 304 x 256 map; no per-blade CPU work.

const ORIGIN := Vector2(-76, -64)
const SIZE := Vector2(152, 128)
const CELL: float = 0.5
const RADIUS: float = 0.85
const RECOVERY: float = 1.15
const NEUTRAL := Color(128.0 / 255.0, 128.0 / 255.0, 0, 1)
var image: Image
var texture: ImageTexture
var bends: Dictionary[Vector2i, Vector2] = {}
var _dirty: bool = false

func _init() -> void:
	image = Image.create(int(SIZE.x / CELL), int(SIZE.y / CELL), false, Image.FORMAT_RGBA8)
	image.fill(NEUTRAL)
	texture = ImageTexture.create_from_image(image)

func bind(material: ShaderMaterial) -> void:
	material.set_shader_parameter("bend_map", texture)
	material.set_shader_parameter("bend_origin", ORIGIN)
	material.set_shader_parameter("bend_size", SIZE)

func recover(delta: float) -> void:
	var decay := exp(-maxf(delta, 0.0) * RECOVERY)
	for cell: Vector2i in bends.keys():
		var bend := bends[cell] * decay
		if bend.length() < 0.015:
			bends.erase(cell)
			image.set_pixelv(cell, NEUTRAL)
		else:
			bends[cell] = bend
			_write(cell, bend)
		_dirty = true

func press(from: Vector2, to: Vector2) -> void:
	# Relocations never draw a flattened stripe across the world.
	if from.distance_squared_to(to) > 16.0: from = to
	var motion := to - from
	var low := Vector2i(((from.min(to) - Vector2.ONE * RADIUS - ORIGIN) / CELL).floor())
	var high := Vector2i(((from.max(to) + Vector2.ONE * RADIUS - ORIGIN) / CELL).floor())
	low = low.max(Vector2i.ZERO)
	high = high.min(Vector2i(image.get_width() - 1, image.get_height() - 1))
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var cell := Vector2i(x, y)
			var at := ORIGIN + (Vector2(cell) + Vector2.ONE * 0.5) * CELL
			var along := clampf((at - from).dot(motion) / maxf(motion.length_squared(), 0.0001), 0, 1)
			var away := at - (from + motion * along)
			if away.length() >= RADIUS: continue
			var weight := 1.0 - smoothstep(0.12, RADIUS, away.length())
			var direction := (away.normalized() + motion.limit_length(0.7)).normalized()
			if direction.is_zero_approx(): direction = Vector2.RIGHT
			var bend := direction * weight
			if bends.has(cell) and bends[cell].length() > weight: continue
			bends[cell] = bend
			_write(cell, bend)
			_dirty = true

func upload() -> void:
	if not _dirty: return
	texture.update(image)
	_dirty = false

func _write(cell: Vector2i, bend: Vector2) -> void:
	image.set_pixelv(cell, Color((bend.x * 127 + 128) / 255, (bend.y * 127 + 128) / 255, bend.length(), 1))
