class_name BattlePresentation
extends RefCounted
## Reuses embedded Tofufu art and inventory icons. All effects are cosmetic.

var game: BattleRoyaleGame
var gunfire := BattleGunfirePings.new()
var loot_sprites: Array[Sprite3D] = []
var weapons: Array[Sprite3D] = []
var shots: Array[int] = []
var poses: Array[float] = []
var fallen: Array[bool] = []
var feed: Array[int] = []
var names: Array[Label3D] = []
var _locale: String = ""
var ring_mesh := ImmediateMesh.new()
var traces := ImmediateMesh.new()
var ring_clock: float = 1
var icons: Array[Texture2D] = []
var skin_textures: Array[Texture2D] = []
var _lines: Array = []
var _material: StandardMaterial3D

func build() -> void:
	gunfire.game = game
	gunfire.reset()
	# Hold every atlas through the match, so a first jump/attack cannot load art mid-fight.
	for id: String in TofufuTestArt.IDS:
		for category: String in ["locomotion", "jump", "melee"]:
			skin_textures.append(load(TofufuTestArt.ROOT + id + "/" + category + ".png") as Texture2D)
	for kind in BattleGear.LOOT_WEAPONS:
		icons.append(BattleBalance.item(kind).icon if kind > 0 else null)
	icons[2] = load("res://assets/combat/shell_piece.svg") as Texture2D
	icons[3] = InventoryItem.apple().icon
	icons[4] = InventoryItem.create_edamame().icon
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.vertex_color_use_as_albedo = true
	for mesh: ImmediateMesh in [ring_mesh, traces]:
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		game.add_child(instance)
	for slot in game.bodies.size():
		shots.append(0)
		poses.append(0.0)
		fallen.append(false)
		var label := Label3D.new()
		label.text = game.name_of(slot)
		if slot != game.local_slot and BattleTeams.allies(game.room.options, slot, game.local_slot): label.modulate = Color("78e5ef")
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.position = Vector3(0, 1.6, 0)
		label.font_size = 25
		label.pixel_size = 0.01
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.visibility_range_end = 26
		label.no_depth_test = false
		game.bodies[slot].add_child(label)
		names.append(label)

func update(delta: float) -> void:
	gunfire.update(delta)
	if _locale != TranslationServer.get_locale():
		_locale = TranslationServer.get_locale()
		for slot in names.size(): names[slot].text = game.name_of(slot)
	for slot in game.bodies.size():
		var row: Array = game.match_state.rows[slot]
		poses[slot] = maxf(0, poses[slot] - delta)
		game.bodies[slot].visible = row[8] > 0
		if row[8] <= 0 and not fallen[slot]:
			feed.append(slot)
			if feed.size() > 3: feed.remove_at(0)
		fallen[slot] = row[8] <= 0
	_update_loot()
	ring_clock += delta
	if ring_clock >= 0.25:
		ring_clock = 0
		_ring()
	traces.clear_surfaces()
	if not _lines.is_empty():
		traces.surface_begin(Mesh.PRIMITIVE_LINES, _material)
		for line: Array in _lines.duplicate():
			line[2] -= delta
			traces.surface_set_color(Color("ffdb78"))
			traces.surface_add_vertex(line[0])
			traces.surface_add_vertex(line[1])
			if line[2] <= 0: _lines.erase(line)
		traces.surface_end()

func strike(slot: int) -> Dictionary:
	if poses.size() <= slot or poses[slot] <= 0: return {}
	var row: Array = game.match_state.rows[slot]
	if row[10] == 2: return {}
	return {"style": int(row[14]) % 4, "elapsed": 0.24 - poses[slot], "duration": 0.24, "aim": Vector2(row[6], row[7])}

func feed_text() -> String:
	var lines := PackedStringArray()
	for slot in feed: lines.append(tr("%s was eliminated") % game.name_of(slot))
	return "\n".join(lines)

func _update_loot() -> void:
	for i in game.match_state.loot.size():
		var row: Array = game.match_state.loot[i]
		if i >= loot_sprites.size():
			var sprite := _sprite()
			sprite.texture = icons[int(row[4])]
			sprite.pixel_size = 0.7 / sprite.texture.get_height()
			sprite.visibility_range_end = 45
			game.add_child(sprite)
			loot_sprites.append(sprite)
		loot_sprites[i].position = Vector3(row[1], row[2] + 0.55, row[3])
		if loot_sprites[i].texture != icons[int(row[4])]:
			loot_sprites[i].texture = icons[int(row[4])]
			loot_sprites[i].pixel_size = 0.7 / loot_sprites[i].texture.get_height()
		loot_sprites[i].visible = row[5] == 1

func _ring() -> void:
	ring_mesh.clear_surfaces()
	ring_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _material)
	var radius := BattleRing.radius(game.match_state.time)
	for i in 128:
		for j in [i, i + 1]:
			var angle: float = float(j) * TAU / 128
			var p := BattleRing.center(game.match_state.time, game.match_state.circle) + Vector2(cos(angle), sin(angle)) * radius
			ring_mesh.surface_set_color(Color("e58aff"))
			ring_mesh.surface_add_vertex(game.world.ground_point(p.x, p.y, 0.3))
	ring_mesh.surface_end()

func _sprite() -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	return sprite
