class_name CastleStairways
extends RefCounted
## Two shallow flights and broad, level turns join each pair of maze decks.

static func build(parent: Node3D, deck: int) -> Node3D:
	var stairs := Node3D.new()
	stairs.name = "RoyalStairway%d" % deck
	parent.add_child(stairs)
	var side := -1.0 if deck % 2 == 0 else 1.0
	var height := deck * 8.0
	CastleGeometry.ramp(stairs, Vector3(0, height, side * 27), Vector3(0, height + 4, side * 50), 5.6)
	CastleGeometry.solid(stairs, Vector3(4, height + 3.75, side * 53), Vector3(13.6, 0.5, 6), Color("967862"))
	CastleGeometry.ramp(stairs, Vector3(8, height + 4, side * 50), Vector3(8, height + 8, side * 33), 5.6)
	CastleGeometry.solid(stairs, Vector3(4, height + 7.75, side * 30), Vector3(13.6, 0.5, 6), Color("967862"))
	CastleGeometry.solid(stairs, Vector3(4, height + 5.2, side * 56), Vector3(13.6, 2.4, 0.35), Color("453740"))
	for x in [-2.85, 10.85]:
		CastleGeometry.solid(stairs, Vector3(x, height + 5.2, side * 53), Vector3(0.35, 2.4, 6), Color("453740"))
		CastleGeometry.solid(stairs, Vector3(x, height + 9.2, side * 30), Vector3(0.35, 2.4, 6), Color("453740"))
	CastleGeometry.solid(stairs, Vector3(4, height + 9.2, side * 26.8), Vector3(5, 2.4, 0.35), Color("453740"))
	CastleGeometry.title(stairs, Vector3(4, height + 5.2, side * 54.7), "ROYAL ASCENT · %d" % (deck + 1), 22)
	return stairs
