class_name KingCombatFrames
extends RefCounted
## Atlas crops measured from alpha, with per-view standing scale and foot anchors.

const SHEETS: Array[Texture2D] = [
	preload("res://assets/characters/lava_king/combat/lava-king-combat-north.png"),
	preload("res://assets/characters/lava_king/combat/lava-king-combat-north-east.png"),
	preload("res://assets/characters/lava_king/combat/lava-king-combat-east.png"),
	preload("res://assets/characters/lava_king/combat/lava-king-combat-south-east.png"),
	preload("res://assets/characters/lava_king/combat/lava-king-combat-south.png")]
const BOUNDS: Array[Array] = [
	[[55, 150, 414, 348, 227.286036036036], [585, 152, 380, 347, 723.1581769437], [1105, 36, 389, 462, 1279.55287260616], [35, 605, 581, 342, 339.621487603306], [627, 627, 404, 313, 825.882681564246], [1083, 597, 394, 358, 1273.47896039604]],
	[[34, 98, 462, 383, 240.43137254902], [541, 98, 454, 383, 715.90780141844], [1049, 26, 469, 454, 1287.10321864595], [18, 599, 592, 336, 260.62339055794], [586, 597, 433, 332, 820.03317535545], [1059, 641, 419, 312, 1304.03451995685]],
	[[41, 91, 425, 387, 297.684719535783], [575, 91, 391, 388, 783.622401847575], [1069, 60, 422, 418, 1247.98423127464], [22, 600, 550, 364, 203.874051593323], [649, 599, 332, 369, 749.406666666667], [1072, 633, 424, 322, 1257.79245283019]],
	[[60, 115, 399, 388, 300.165048543689], [555, 124, 395, 379, 796.563253012048], [1045, 43, 427, 459, 1233.68073394495], [44, 604, 525, 365, 176.479591836735], [584, 590, 440, 372, 761.485039370079], [1095, 637, 381, 328, 1288.42857142857]],
	[[40, 61, 455, 436, 240.837620578778], [563, 61, 436, 435, 758.86546184739], [1045, 16, 470, 477, 1299.01496259352], [10, 583, 538, 378, 332.193808882907], [577, 605, 442, 355, 870.113938053097], [1107, 637, 391, 322, 1257.56862745098]]]
var frames: Array[Array] = []

func _init() -> void:
	for view in 5:
		var row: Array[AtlasTexture] = []
		for pose in 6:
			var box: Array = BOUNDS[view][pose]
			var atlas := AtlasTexture.new()
			atlas.atlas = SHEETS[view]
			atlas.region = Rect2(box[0], box[1], box[2], box[3])
			row.append(atlas)
		frames.append(row)

func present(sprite: Sprite3D, view: int, pose: int, mirrored: bool, height: float) -> void:
	var box: Array = BOUNDS[view][pose]
	var standing_height: float = (BOUNDS[view][0][3] + BOUNDS[view][1][3]) * 0.5
	sprite.texture = frames[view][pose]
	sprite.pixel_size = height / standing_height
	var anchor_x: float = box[0] + box[2] * 0.5 - box[4]
	sprite.offset = Vector2(-anchor_x if mirrored else anchor_x, box[3] * 0.5 + 0.05 / sprite.pixel_size)
