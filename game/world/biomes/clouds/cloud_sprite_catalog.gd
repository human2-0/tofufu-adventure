class_name CloudSpriteCatalog
extends RefCounted
## Measured alpha silhouettes and sole pivots; original generated atlases stay intact.

const ART: Dictionary = {
	"godfufu": {
		"sheet": preload("res://assets/characters/cloud_court/godfufu-directions.png"),
		"bounds": [Rect2(7, 71, 454, 568), Rect2(481, 65, 424, 585), Rect2(921, 72, 310, 581), Rect2(1257, 75, 432, 586), Rect2(1712, 70, 452, 572)],
		"anchors": [Vector2(234.0, 639), Vector2(693.0, 650), Vector2(1083.5, 653), Vector2(1465.0, 661), Vector2(1938.0, 642)],
		"flip_cells": [3]},
	"goddess": {
		"sheet": preload("res://assets/characters/cloud_court/goddess-directions-v2.png"),
		"bounds": [Rect2(27, 139, 405, 430), Rect2(471, 140, 407, 431), Rect2(920, 137, 332, 433), Rect2(1296, 135, 409, 437), Rect2(1752, 136, 394, 436)],
		"anchors": [Vector2(233.0, 569), Vector2(680.5, 571), Vector2(1064.0, 570), Vector2(1490.5, 572), Vector2(1949.0, 572)],
		"flip_cells": []},
	"guardian": {
		"sheet": preload("res://assets/characters/cloud_court/guardian-directions-v2.png"),
		"bounds": [Rect2(15, 80, 396, 522), Rect2(472, 74, 411, 541), Rect2(922, 69, 319, 551), Rect2(1319, 132, 399, 495), Rect2(1754, 99, 410, 515)],
		"anchors": [Vector2(213.0, 602), Vector2(677.5, 615), Vector2(1081.5, 620), Vector2(1518.5, 627), Vector2(1959.0, 614)],
		"flip_cells": [3]},
	"nimbus": {
		"sheet": preload("res://assets/characters/cloud_court/nimbus-directions-v2.png"),
		"bounds": [Rect2(26, 70, 429, 574), Rect2(492, 76, 392, 572), Rect2(929, 76, 351, 572), Rect2(1325, 75, 410, 579), Rect2(1740, 71, 412, 577)],
		"anchors": [Vector2(240.5, 644), Vector2(688.0, 648), Vector2(1079.5, 648), Vector2(1534.0, 654), Vector2(1946.0, 648)],
		"flip_cells": [2]},
	"petal": {
		"sheet": preload("res://assets/characters/cloud_court/petal-directions-v2.png"),
		"bounds": [Rect2(32, 123, 409, 486), Rect2(485, 121, 429, 496), Rect2(913, 121, 356, 497), Rect2(1296, 122, 411, 500), Rect2(1738, 121, 399, 493)],
		"anchors": [Vector2(230.0, 609), Vector2(694.5, 617), Vector2(1103.0, 618), Vector2(1502.5, 622), Vector2(1940.5, 614)],
		"flip_cells": []},
	"mallow": {
		"sheet": preload("res://assets/characters/cloud_court/mallow-directions.png"),
		"bounds": [Rect2(27, 111, 380, 502), Rect2(472, 105, 409, 518), Rect2(917, 104, 391, 519), Rect2(1338, 112, 408, 516), Rect2(1799, 111, 339, 510)],
		"anchors": [Vector2(213.0, 613), Vector2(656.0, 623), Vector2(1068.0, 623), Vector2(1542.0, 628), Vector2(1968.5, 621)],
		"flip_cells": []},
	"lumen": {
		"sheet": preload("res://assets/characters/cloud_court/lumen-directions.png"),
		"bounds": [Rect2(38, 138, 417, 463), Rect2(480, 129, 421, 491), Rect2(918, 126, 368, 489), Rect2(1308, 124, 418, 492), Rect2(1751, 123, 392, 478)],
		"anchors": [Vector2(242.5, 601), Vector2(671.0, 620), Vector2(1067.5, 615), Vector2(1511.0, 616), Vector2(1941.5, 601)],
		"flip_cells": []},
	"pearl": {
		"sheet": preload("res://assets/characters/cloud_court/pearl-directions.png"),
		"bounds": [Rect2(31, 107, 375, 528), Rect2(494, 94, 393, 553), Rect2(927, 104, 347, 540), Rect2(1333, 112, 378, 536), Rect2(1778, 111, 341, 539)],
		"anchors": [Vector2(218.5, 635), Vector2(674.0, 647), Vector2(1100.5, 644), Vector2(1539.5, 648), Vector2(1948.5, 650)],
		"flip_cells": []},
	"angel": {
		"sheet": preload("res://assets/characters/cloud_court/angel-directions.png"),
		"bounds": [Rect2(53, 45, 351, 320), Rect2(482, 43, 299, 320), Rect2(869, 46, 202, 317), Rect2(1207, 51, 301, 308), Rect2(1580, 54, 349, 309), Rect2(34, 422, 390, 319), Rect2(462, 420, 345, 320), Rect2(840, 425, 231, 315), Rect2(1181, 430, 345, 307), Rect2(1565, 432, 381, 309)],
		"anchors": [Vector2(228.0, 365), Vector2(609.5, 363), Vector2(970.5, 363), Vector2(1344.5, 359), Vector2(1754.0, 363), Vector2(229.0, 741), Vector2(608.5, 740), Vector2(970.5, 740), Vector2(1344.5, 737), Vector2(1754.0, 741)],
		"flip_cells": []},
}

static func entry(asset: String) -> Dictionary:
	return ART.get(asset, ART["guardian"])

static func crop(bounds: Array[Rect2], index: int) -> Rect2:
	var own := bounds[index]
	var region := own.grow(4)
	for other in bounds:
		if other == own or other.position.y >= own.end.y or other.end.y <= own.position.y: continue
		if other.get_center().x > own.get_center().x:
			region.end.x = minf(region.end.x, other.position.x - 1)
		else:
			var right := region.end.x
			region.position.x = maxf(region.position.x, other.end.x + 1)
			region.end.x = right
	return region
