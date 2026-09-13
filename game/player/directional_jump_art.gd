class_name DirectionalJumpArt
extends RefCounted
## Four authored left/back rows supply seven directions with runtime mirroring.
const SOURCE = preload("res://assets/characters/fufu/jump/directional/atlas.png")
const SHADER = preload("res://game/player/jump_atlas.gdshader")
const REGIONS: Array[Rect2] = [
	Rect2(46,57,147,182), Rect2(244,31,130,202), Rect2(437,39,138,186), Rect2(637,16,148,190), Rect2(827,44,142,184), Rect2(1035,16,111,220), Rect2(1214,64,135,178), Rect2(1402,108,168,137), Rect2(1624,66,138,175), Rect2(1814,64,132,175),
	Rect2(51,258,127,180), Rect2(250,233,110,198), Rect2(437,237,129,186), Rect2(642,228,135,181), Rect2(830,241,129,190), Rect2(1036,233,105,206), Rect2(1216,266,126,177), Rect2(1403,313,170,132), Rect2(1628,266,125,173), Rect2(1824,265,117,174),
	Rect2(54,460,122,168), Rect2(243,432,121,192), Rect2(434,438,131,179), Rect2(630,429,150,181), Rect2(832,449,135,178), Rect2(1031,441,116,190), Rect2(1220,467,133,171), Rect2(1407,519,161,119), Rect2(1630,467,132,167), Rect2(1819,467,130,167),
	Rect2(48,641,133,148), Rect2(249,626,121,162), Rect2(448,629,124,160), Rect2(639,623,138,161), Rect2(836,633,133,157), Rect2(1031,628,116,161), Rect2(1220,641,129,148), Rect2(1410,678,152,112), Rect2(1624,639,132,150), Rect2(1818,638,123,151)]
const ROWS: Array[int] = [1, 0, -1, 0, 1, 2, 3, 2]
const HAND_X: Array[float] = [0.77, 0.78, 0.2, 0.87]
var hand := Vector2.ZERO
var _atlas := AtlasTexture.new()
var _material := ShaderMaterial.new()

func _init() -> void:
	_atlas.atlas = SOURCE
	_material.shader = SHADER
	_material.set_shader_parameter("atlas", SOURCE)

func apply(sprite: Sprite3D, facing: int, phase: int) -> bool:
	var row := ROWS[facing]
	if row < 0: return false
	var bounds := REGIONS[row * 10 + phase]
	_atlas.region = bounds
	sprite.texture = _atlas
	sprite.hframes = 1
	sprite.vframes = 1
	sprite.frame = 0
	sprite.flip_h = facing in [0, 1, 7]
	sprite.pixel_size = 1.12 / REGIONS[row * 10 + 9].size.y
	sprite.offset = Vector2(0, bounds.size.y * 0.5 - 2.0 - 0.56 / sprite.pixel_size)
	sprite.material_override = _material
	var hand_y := 0.68
	if phase in [1, 2, 3, 4]: hand_y = 0.48
	if phase == 7: hand_y = 0.77
	hand = Vector2(HAND_X[row], hand_y) * bounds.size
	return true
