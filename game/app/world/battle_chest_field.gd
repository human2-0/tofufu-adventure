class_name BattleChestField
extends RefCounted
## Tier-specific textured treasure models and pooled, distance-culled drop icons.
var game: BattleRoyaleGame
var chests: Array[BattleChestModel] = []
var blockers: Array = []
var drops: Array[Sprite3D] = []
var icons: Array[Texture2D] = []
var _chest_cache: Array = []
var _drop_cache: Array = []

func update(animate: bool = true) -> void:
	if icons.is_empty():
		for i in BattlePackWire.ITEMS.size(): icons.append(BattleItems.make(i + 1).icon)
	if game.match_state.chests != _chest_cache:
		for i in game.match_state.chests.size():
			var row: Array = game.match_state.chests[i]
			if i >= chests.size():
				var model := BattleChestModel.new()
				model.tier = int(row[5])
				game.add_child(model)
				chests.append(model)
				var bodies: Array[RID] = []
				for child in model.get_children():
					if child is CollisionObject3D: bodies.append(child.get_rid())
				_cull(model)
				blockers.append(bodies)
			chests[i].position = Vector3(row[1], row[2], row[3])
			chests[i].present(row[4] == 1, row[4] == 0, animate)
		_chest_cache = game.match_state.chests.duplicate(true)
	if game.match_state.drops == _drop_cache: return
	for i in game.match_state.drops.size():
		var row: Array = game.match_state.drops[i]
		if i >= drops.size():
			var sprite := Sprite3D.new()
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.shaded = false
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			sprite.visibility_range_end = 45
			sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			game.add_child(sprite)
			drops.append(sprite)
		drops[i].texture = icons[int(row[4]) - 1]
		drops[i].pixel_size = 0.65 / drops[i].texture.get_height()
		drops[i].position = Vector3(row[1], row[2] + 0.4, row[3])
		drops[i].visible = row[5] > 0
	for i in range(game.match_state.drops.size(), drops.size()): drops[i].hide()
	_drop_cache = game.match_state.drops.duplicate(true)

func _cull(node: Node) -> void:
	if node is GeometryInstance3D: node.visibility_range_end = 65
	for child in node.get_children(): _cull(child)
