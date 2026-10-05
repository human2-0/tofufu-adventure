class_name DungeonPuzzleAnchors
extends RefCounted
## Reusable camera targets for authored factory interactions.

var anchors: Dictionary = {}

func get_anchor(dungeon: TofuDungeon, identity: String) -> Node3D:
	if anchors.has(identity) and is_instance_valid(anchors[identity]): return anchors[identity]
	var anchor := Node3D.new()
	anchor.position = TofuFactory.object_position(identity)
	dungeon.factory.add_child(anchor)
	anchors[identity] = anchor
	return anchor
