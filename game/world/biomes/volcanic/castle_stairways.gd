class_name CastleStairways
extends RefCounted
## Three external switchbacks connect alternating maze exits to the next deck.

static func build(parent: Node3D, deck: int) -> Node3D:
	var stairs := Node3D.new()
	stairs.name = "RoyalStairway%d" % deck
	parent.add_child(stairs)
	var side := -1.0 if deck % 2 == 0 else 1.0
	var height := deck * 8.0
	var start := Vector3(0, height, side * 27)
	var end := Vector3(0, height + 8, side * 54)
	CastleGeometry.ramp(stairs, start, end, 4.6)
	CastleGeometry.solid(stairs, Vector3(3.5, height + 7.75, side * 55), Vector3(11.6, 0.5, 5), Color("967862"))
	CastleGeometry.solid(stairs, Vector3(7, height + 7.75, side * 40), Vector3(4.6, 0.5, 29), Color("967862"))
	CastleGeometry.solid(stairs, Vector3(3.5, height + 7.75, side * 27), Vector3(11.6, 0.5, 5), Color("967862"))
	for x in [4.5, 9.5]:
		CastleGeometry.solid(stairs, Vector3(x, height + 9.5, side * 41), Vector3(0.4, 3, 27), Color("453740"))
	CastleGeometry.solid(stairs, Vector3(3.5, height + 9.5, side * 57.4), Vector3(11.6, 3, 0.4), Color("453740"))
	return stairs
