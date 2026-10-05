class_name DungeonRecovery
extends RefCounted
## Authority restores an in-run actor after an illegal room transition.

var anchors: Dictionary = {}
var rooms: Dictionary = {}

func step(dungeon: TofuDungeon) -> void:
	for node: Node3D in dungeon._actors_inside():
		var actor := node as Player
		if actor == null: continue
		var key: String = DungeonMembership.key_for(dungeon, actor)
		if key.is_empty(): continue
		var current: int = TofuFactory.room_at(actor.global_position)
		if not anchors.has(key):
			var initial: int = clampi(dungeon.state.stage - 1, 0, 5)
			anchors[key] = TofuFactory.recovery_anchor(initial)
			rooms[key] = initial
		var previous: int = int(rooms[key])
		if current < 0 or not TofuFactory.permitted_transition(previous, current, dungeon.state.stage):
			_recover(dungeon, actor, key)
			continue
		var shape := actor.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape != null and actor.is_on_floor() and dungeon.factory.anchor_has_clearance(actor, shape, actor.global_position, dungeon.state.stage):
			anchors[key] = actor.global_position
			rooms[key] = current

func seed(key: String, at: Vector3, room: int) -> void:
	anchors[key] = at
	rooms[key] = room

func forget(key: String) -> void:
	anchors.erase(key)
	rooms.erase(key)

func _recover(dungeon: TofuDungeon, actor: Player, key: String) -> void:
	actor.relocate(anchors[key])
	actor.velocity = Vector3.ZERO
	actor.motor.is_dashing = false
	actor.motor.is_super_dashing = false
	dungeon._carrying.erase(actor)
	if dungeon.puzzle_enabled: dungeon.puzzle_runtime.release_actor(actor)
	dungeon.factory.show_cargo(dungeon.cargo_positions())
