class_name WorldItemVisuals
extends RefCounted
## Dropped gear uses compact versions of its existing artwork.

const APPAREL_DROP_SPANS: Dictionary = {"helmet": 0.38, "armor": 0.44, "legs": 0.38, "boots": 0.34}

static func build(drop: WorldItemDrop) -> void:
	if drop.item_id == "knife":
		var sprite := Sprite3D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SwordVisual.ATLAS
		atlas.region = Rect2(0, 0, 460, 420)
		sprite.texture = atlas
		sprite.pixel_size = 0.0015
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)
	elif drop.item_id == "soy_gun":
		var sprite := Sprite3D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = SoyGunVisual.ABOVE
		atlas.region = SoyGunVisual.TOP_REGIONS[2]
		sprite.texture = atlas
		sprite.pixel_size = 0.0016
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)
	elif drop.item_id == "sotjet":
		var sprite := SotjetVisual.new()
		drop.add_child(sprite)
		sprite.set_process(false)
		sprite.visible = true
		sprite.frame = 2
		sprite.pixel_size = 0.0015
	elif drop.item_id == "sproutwood_staff":
		var staff := StaffVisual.new()
		drop.add_child(staff)
		staff.rotation.x = -PI * 0.5
		staff.scale = Vector3.ONE * 0.62
	elif drop.item_id == "seed_satchel":
		_seed_satchel(drop)
	elif drop.item_id in ["factory_backpack", "traveler_backpack"]:
		var sprite := Sprite3D.new()
		sprite.texture = InventoryIconQuality.for_slot(InventoryItem.backpack(drop.item_id).icon)
		sprite.pixel_size = 0.65 / maxf(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)
	elif drop.item_id == "piece_of_shell":
		var shell := SphereMesh.new()
		shell.radius = 0.28
		shell.height = 0.22
		shell.radial_segments = 10
		shell.rings = 5
		shell.material = MeadowGeometry.material(Color("8a765c"))
		var shell_piece := MeshInstance3D.new()
		shell_piece.mesh = shell
		shell_piece.position.y = 0.12
		drop.add_child(shell_piece)
	elif drop.item_id == "soy_milk":
		var milk := Sprite3D.new()
		milk.texture = preload("res://assets/factory/soy_milk.svg")
		milk.pixel_size = 0.006
		milk.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(milk)
	elif drop.item_id.begins_with("bright_leaf_") or drop.item_id.begins_with("dark_leaf_"):
		_apparel(drop)
	else:
		var sprite := Sprite3D.new()
		var art := CurrencyVisuals.icon(drop.item_id, drop.count)
		if art == null: return
		sprite.texture = InventoryIconQuality.for_slot(art)
		sprite.pixel_size = 0.5 / maxf(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		drop.add_child(sprite)

static func _apparel(drop: WorldItemDrop) -> void:
	var item := InventoryItem.apparel(drop.item_id)
	if item == null or item.icon == null: return
	var sprite := Sprite3D.new()
	sprite.texture = item.icon
	sprite.pixel_size = APPAREL_DROP_SPANS.get(item.category, 0.38) / maxf(float(sprite.texture.get_width()), float(sprite.texture.get_height()))
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	var image := sprite.texture.get_image()
	if image.is_compressed(): image.decompress()
	var used := image.get_used_rect()
	if used.has_area():
		var alpha_bottom := used.position.y + used.size.y - 1
		sprite.offset.y = alpha_bottom - image.get_height() * 0.5 - WorldItemDrop.RADIUS / sprite.pixel_size
	drop.add_child(sprite)

static func _seed_satchel(drop: WorldItemDrop) -> void:
	var pack := Node3D.new()
	pack.position.y = 0.1
	drop.add_child(pack)
	_box(pack, Vector3(0, 0.38, 0), Vector3(0.62, 0.72, 0.22), Color("d69657"))
	_box(pack, Vector3(0, 0.66, 0.03), Vector3(0.68, 0.16, 0.27), Color("f0c76e"))
	_box(pack, Vector3(0, 0.51, 0.15), Vector3(0.12, 0.12, 0.04), Color("7e9e87"))
	for side in [-1.0, 1.0]:
		_box(pack, Vector3(side * 0.24, 0.46, -0.13), Vector3(0.08, 0.52, 0.05), Color("6d5549"))

static func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
